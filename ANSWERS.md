# Part 5 — Gateway API migration

I would start by inventorying all 40 Ingresses: hosts, paths, TLS secrets, annotations, auth, rewrites, timeouts, rate limits, traffic, and dependencies. I’d group them by configuration pattern and identify ingress-nginx-specific behavior that needs an explicit Gateway API equivalent. I’d also confirm the chosen Gateway controller supports the required features and install its CRDs and controller alongside ingress-nginx.

Next, I’d create the Gateway, listeners, policies, and HTTPRoutes for a small, representative set of services. I’d validate route precedence, hostname and path matching, TLS and certificate renewal, redirects, authentication, and health checks in a staging environment. Then I’d run both controllers in parallel and test the new routes using a temporary hostname or direct load-balancer address.

For production, I’d migrate in small batches, shifting traffic gradually through the load balancer or DNS while monitoring error rates, latency, and controller events. I’d keep the original Ingresses and ingress-nginx available as a rollback path until each batch meets agreed success criteria and existing connections have drained. I’d document an owner and rollback command for every batch.

I expect annotation gaps, route precedence differences, TLS mistakes, and controller-specific behavior to break first. DNS caching and long-lived connections can also make cutovers uneven. After a stable observation period, I’d remove obsolete Ingresses and retire ingress-nginx. I would not decommission it before confirming all routes, policies, and operational alerts have equivalents.
