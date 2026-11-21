# Enterprise Bot DevOps Platform

## Run and verify

From the repository root, create or reuse the `demo` kind cluster, build and
load the service image, install ingress-nginx, and deploy the Helm release:

```bash
./setup.sh
```

Check the release and Kubernetes resources:

```bash
helm lint chart
helm status demo --kube-context kind-demo --namespace demo
kubectl --context kind-demo --namespace demo get deployment,pods,service
kubectl --context kind-demo --namespace demo rollout status deployment/demo-enterprisebot-devops-platform
```

Check the service through the `demo.local` Ingress on host port 8080:

```bash
curl --fail --resolve demo.local:8080:127.0.0.1 http://demo.local:8080/
curl --fail --resolve demo.local:8080:127.0.0.1 http://demo.local:8080/healthz
```

Part 4's debug lab can be run from a Bash/WSL shell with the cluster context
configured:

```bash
cd lab
./scenario.sh up
./scenario.sh verify
```

The latest recorded Part 4 verification was not all green; the reporter still
returns a pod-list parsing error. Treat that lab as incomplete until a fresh
verification passes.

## Resource requests and limits

The application chart defaults to two replicas. Each container requests
`100m` CPU and `64Mi` memory, with limits of `500m` CPU and `128Mi` memory.
These are conservative starting values for this lightweight service: requests
reserve schedulable baseline capacity, while limits cap resource consumption.
They have not been tuned using production load tests; measure actual CPU and
memory under representative traffic before changing them for a real deployment.

## Deliberately skipped work and risks

This local kind exercise does not include horizontal autoscaling, a
PodDisruptionBudget, persistent application storage, production DNS/TLS
certificate management, centralized metrics/logging/tracing, network policies,
or an automated image/security scanning pipeline. Without these, the service
has no automatic capacity response, limited resilience to node disruption,
reduced observability, and no production-grade ingress or security controls.
The image and resource settings also have not been validated under realistic
load.

## Production readiness

Before production, I would load-test and right-size resources, add autoscaling
and disruption budgets, define SLOs and alerts, centralize logs and metrics,
and verify backup and recovery needs. I would also add CI for tests, chart
validation, image scanning and SBOM generation; use managed secrets and
automated TLS; apply least-privilege RBAC and network policies; and validate
rolling upgrades and rollback procedures in a staging environment.

## How I Used AI

I used GitHub Copilot in VS Code at different stages of the assignment, mainly for:

- **Dockerfile:** Getting assistance with drafting the initial multi-stage Dockerfile and reviewing Docker build configurations.
- **Command assistance:** Checking command syntax and understanding the usage of Docker, Kind, Helm, and kubectl commands.
- **Troubleshooting:** Sharing terminal errors and Kubernetes logs with Copilot to understand possible causes and identify relevant diagnostic commands.
- **Documentation:** Using Copilot to organize and refine the README and technical explanations.

During Part 4, I used Copilot to help interpret actual container logs. This helped identify that the provided image listened on port 8081 and that the worker required a writable cache directory. I verified these findings against the cluster behaviour. The reporter's remaining pod-list parsing issue is documented as unresolved.
