{{/*
# Human Tasks:
# 1. Verify Kubernetes cluster meets minimum version requirements (v1.24+)
# 2. Ensure Helm v3.0+ is installed
# 3. Validate chart values.yaml exists and contains required configuration
# 4. Confirm proper RBAC permissions for Helm service account
*/}}

{{/*
Addresses requirement: Infrastructure as Code (2.5.2 Deployment Architecture/Helm)
Generates a consistent name for all resources based on chart name and optional override
*/}}
{{- define "web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Addresses requirement: Infrastructure as Code (2.5.2 Deployment Architecture/Helm)
Generates a fully qualified app name combining release name and chart name
*/}}
{{- define "web.fullname" -}}
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
Addresses requirement: Infrastructure as Code (2.5.2 Deployment Architecture/Helm)
Generates the chart name and version as used by the chart label
*/}}
{{- define "web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Addresses requirements:
- Infrastructure as Code (2.5.2 Deployment Architecture/Helm)
- High Availability (2.5.4 Availability Architecture)
- Web Application Deployment (2.1 High-Level Architecture Overview/Client Layer)

Common labels to be used across all resources following Kubernetes best practices
*/}}
{{- define "web.labels" -}}
helm.sh/chart: {{ include "web.chart" . }}
app.kubernetes.io/name: {{ include "web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: web
app.kubernetes.io/part-of: mint-replica-lite
{{- if .Values.global }}
environment: {{ .Values.global.environment }}
region: {{ .Values.global.region }}
{{- end }}
{{- end }}

{{/*
Addresses requirements:
- Infrastructure as Code (2.5.2 Deployment Architecture/Helm)
- High Availability (2.5.4 Availability Architecture)

Selector labels used by the deployment for pod selection
*/}}
{{- define "web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: web
{{- end }}