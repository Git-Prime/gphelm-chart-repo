{{/* Creates a value that represents the full environment name */}}
{{- define "helpers.environment.fullName" }}
{{- if .Values.environment.modifierValue }}
{{- .Values.environment.parentName }}-{{ .Values.environment.modifierValue }}
{{- else }}
{{- .Values.environment.parentName }}
{{- end }}
{{- end }}

{{/* Creates a value for the right configuration server URL */}}
{{- define "helpers.configServerURL" }}
{{- if eq .Values.environment.parentName "production" }}
{{- "https://prod-config-server.gitprime-ops.com" }}
{{- else }}
{{- "https://config-server.gitprime-ops.com" }}
{{- end }}
{{- end }}

{{- define "gp-pyspark.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gp-pyspark.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gp-pyspark.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "gp-pyspark.labels" -}}
helm.sh/chart: {{ include "gp-pyspark.chart" . }}
{{ include "gp-pyspark.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "gp-pyspark.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gp-pyspark.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "gp-pyspark.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "gp-pyspark.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
