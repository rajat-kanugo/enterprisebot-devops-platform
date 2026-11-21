{{- define "enterprisebot-devops-platform.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprisebot-devops-platform.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "enterprisebot-devops-platform.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "enterprisebot-devops-platform.labels" -}}
app.kubernetes.io/name: {{ include "enterprisebot-devops-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}
