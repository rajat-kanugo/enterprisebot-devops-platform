# Findings — Part 4 debug lab

The recording was started with `script -q part4-session.log` before investigation. The latest captured `./scenario.sh verify` was not green: reporter readiness/reporting and backend/gateway probes still failed. Remaining failures are marked explicitly below rather than claimed as fixed.

## Defect 1 — Migration Job restart policy

**Symptom** (observed during `./scenario.sh up`):

```text
Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never"
```

**Cause:** The Job template used `restartPolicy: Always`, which is not valid for a Job.

**Fix:** Changed the Job to `restartPolicy: Never`; the later verification reported `PASS migrate Job completed`.

**How I found it:** Ran `./scenario.sh up` and followed the server-side apply error to `templates/migrate-job.yaml`.

## Defect 2 — Non-numeric image user

**Symptom** (`kubectl get events` / `kubectl describe pods`):

```text
container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root
```

**Cause:** The chart set `runAsNonRoot: true` but did not set a numeric UID; the image declares its user by the name `nonroot`.

**Fix:** Added `runAsUser: 65532` to the workload container security contexts. New pods subsequently started.

**How I found it:** Inspected pod events and `kubectl describe pod` after the initial install.

## Defect 3 — Metrics CPU exceeded the namespace limit

**Symptom** (ReplicaSet events):

```text
is forbidden: maximum cpu usage per Container is 1, but limit is 4
```

The chart requested `2` CPU and limited metrics to `4`.

**Cause:** Metrics resources exceeded the `debug-lab` LimitRange maximum of `1` CPU.

**Fix:** Reduced metrics CPU request/limit to `100m`/`500m`.

**How I found it:** Read `kubectl get events` and compared the rejection with metrics resources in `values.yaml`.

## Defect 4 — Service port and gateway target configuration

**Symptom** (`kubectl logs` / `kubectl describe pod`):

```text
listening on :8081 (image default is 8081; set PORT to override)
```

The chart probes and service target used port `8080`. The gateway was also configured with `http://backend.default.svc:8080` although the backend is in `debug-lab`.

**Cause:** The image default port and chart port disagreed, and the gateway URL targeted the wrong namespace.

**Fix:** Set `PORT: "8080"` for the app deployments and set `BACKEND_URL` to `http://backend:8080`. Later logs showed backend/gateway endpoints and HTTP 200 responses. However, the latest captured verify still reported backend/gateway probe failures.

**How I found it:** Compared `kubectl describe pod` environment and readiness settings with backend/gateway logs and service endpoints.

**Failure is not yet diagnosed:** The latest verification’s backend and gateway checks have not yet been confirmed green after those later 200 responses.

## Defect 5 — Worker cache on a read-only filesystem

**Symptom** (`kubectl logs deployment/worker --previous`):

```text
FATAL: worker could not initialise its cache: mkdir /var/cache/app: read-only file system
```

**Cause:** The worker needed a writable `/var/cache/app` while the container root filesystem was read-only.

**Fix:** Added an `emptyDir` volume mounted at `/var/cache/app`, keeping the root filesystem read-only. The worker later reported `1/1 Running`, and verification reported no CrashLoopBackOff pods.

**How I found it:** Read the previous worker-container logs after observing its restart.

## Defect 6 — Reporter ServiceAccount binding and remaining parse failure

**Symptom:** Initially, the authorization check returned `no`; the RoleBinding subject was `default` while the reporter Deployment uses ServiceAccount `reporter`. After the binding change, verification reported:

```text
PASS ServiceAccount debug-lab/reporter can list pods
```

But the reporter still logged:

```text
pod list failed: parse pod list: unexpected end of JSON input
```

and its readiness probe returned HTTP 503; the reporter Service had no endpoints.

**Cause:** The initial RoleBinding targeted the wrong ServiceAccount. That mismatch is fixed. The remaining empty/invalid pod-list response is not explained by the passing authorization check.

**Fix:** Changed the RoleBinding subject to `reporter`.

**How I found it:** Checked `kubectl auth can-i`, inspected the RoleBinding, then read logs and described the current reporter pod.

**Failure is not yet diagnosed:** Reporter readiness and `/report` remain failing; the latest verify was not all green.
