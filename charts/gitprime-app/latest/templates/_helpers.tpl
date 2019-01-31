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
