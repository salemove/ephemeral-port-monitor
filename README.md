# Ephemeral Port Monitor

![Docker Image Version (latest semver)](https://img.shields.io/docker/v/salemove/ephemeral-port-monitor)

This tool helps to monitor ephemeral port exhaustion. See
https://making.pusher.com/ephemeral-port-exhaustion-and-how-to-avoid-it/ for
more details about what is and how ephemeral port exhaustion happens.

This tool collects ephemeral port usage using `ss` and returns it in
OpenMetrics format.

## Usage (kubernetes)

Add annotation to your pod:

```
metadata:
  annotations:
    ad.datadoghq.com/ephemeral-port-monitor.check_names: '["openmetrics"]'
    ad.datadoghq.com/ephemeral-port-monitor.init_configs: '[{}]'
    ad.datadoghq.com/ephemeral-port-monitor.instances: |-
      [
        {
          "prometheus_url": "http://%%host%%:9090/metrics",
          "namespace": "transporter",
          "metrics": ["system.net.used_ports.max_count", "system.net.used_ports.count"]
        }
      ]
```

Change the annotations in case you use something else than datadog.

Add a new container:

```
spec:
  containers:
  - name: ephemeral-port-monitor
    image: "salemove/ephemeral-port-monitor:0.1.0"
    ports:
    - name: http
      containerPort: 9090
    env:
    - name: MIN_COUNT_TO_TRACK
      value: "10"
    livenessProbe:
      httpGet:
        path: /healthz
        port: http
    readinessProbe:
      httpGet:
        path: /healthz
        port: http
```

## Releasing a new version

```bash
docker build .
docker tag <BUILD_ID> salemove/ephemeral-port-monitor:0.1.0
docker push salemove/ephemeral-port-monitor:0.1.0
```
