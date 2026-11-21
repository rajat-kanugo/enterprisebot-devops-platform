#!/usr/bin/env bash
set -Eeuo pipefail

readonly CLUSTER_NAME="demo"
readonly KUBE_CONTEXT="kind-${CLUSTER_NAME}"
readonly IMAGE_REPOSITORY="enterprisebot-devops-platform"
readonly IMAGE_TAG="1.0.0"
readonly INGRESS_NGINX_VERSION="controller-v1.12.1"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CHART_DIR="${SCRIPT_DIR}/chart"
readonly SERVICE_DIR="${SCRIPT_DIR}/service"
readonly INGRESS_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"

for command in docker kind kubectl helm; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    printf 'Required command not found in PATH: %s\n' "${command}" >&2
    exit 1
  fi
done

docker info >/dev/null

clusters="$(kind get clusters)"
if printf '%s\n' "${clusters}" | grep -Fxq "${CLUSTER_NAME}"; then
  printf 'Reusing kind cluster %s\n' "${CLUSTER_NAME}"
else
  kind_config="$(mktemp)"
  trap 'rm -f "${kind_config}"' EXIT
  cat > "${kind_config}" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.31.0
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
EOF
  kind create cluster --name "${CLUSTER_NAME}" --config "${kind_config}" --wait 120s
fi

kubectl --context "${KUBE_CONTEXT}" cluster-info >/dev/null
kubectl --context "${KUBE_CONTEXT}" label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite
kubectl --context "${KUBE_CONTEXT}" apply --filename "${INGRESS_MANIFEST_URL}"
kubectl --context "${KUBE_CONTEXT}" wait \
  --namespace ingress-nginx \
  --for=condition=complete \
  job/ingress-nginx-admission-create \
  --timeout=180s
kubectl --context "${KUBE_CONTEXT}" wait \
  --namespace ingress-nginx \
  --for=condition=complete \
  job/ingress-nginx-admission-patch \
  --timeout=180s
kubectl --context "${KUBE_CONTEXT}" wait \
  --namespace ingress-nginx \
  --for=condition=Available \
  deployment/ingress-nginx-controller \
  --timeout=180s

image="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
docker build --tag "${image}" "${SERVICE_DIR}"
kind load docker-image "${image}" --name "${CLUSTER_NAME}"

helm upgrade --install demo "${CHART_DIR}" \
  --kube-context "${KUBE_CONTEXT}" \
  --namespace demo \
  --create-namespace \
  --set-string "image.repository=${IMAGE_REPOSITORY}" \
  --set-string "image.tag=${IMAGE_TAG}" \
  --wait \
  --timeout 5m
