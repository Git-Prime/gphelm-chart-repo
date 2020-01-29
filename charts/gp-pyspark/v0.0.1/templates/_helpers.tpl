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

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create namespace variable
*/}}
{{- define "namespace" -}}
{{- default .Release.Namespace -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "releasename" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
