{{/*
Human Tasks:
1. Verify Helm v3.0+ is installed and configured in the environment
2. Ensure consistent naming conventions are documented for team reference
3. Validate label schema compliance with Kubernetes best practices
*/}}

{{/*
Addresses requirement: Container Orchestration (2.5.1 Production Environment/Application Servers)
Expands the name of the chart or uses nameOverride value from values.yaml
*/}}
{{- define "backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Addresses requirement: Container Orchestration (2.5.1 Production Environment/Application Servers)
Creates a fully qualified app name, combining release name and chart name unless overridden
*/}}
{{- define "backend.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Addresses requirement: Container Orchestration (2.5.1 Production Environment/Application Servers)
Creates chart name and version as used by the chart label
*/}}
{{- define "backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Addresses requirement: High Availability (2.5.4 Availability Architecture)
Common labels for all resources following Kubernetes recommended label schema
*/}}
{{- define "backend.labels" -}}
helm.sh/chart: {{ include "backend.chart" . }}
{{ include "backend.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Addresses requirement: High Availability (2.5.4 Availability Architecture)
Selector labels used for pod affinity and service targeting
*/}}
{{- define "backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Addresses requirement: Security (2.4 Security Architecture)
Service account name for the backend pods with customization support
*/}}
{{- define "backend.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "backend.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}