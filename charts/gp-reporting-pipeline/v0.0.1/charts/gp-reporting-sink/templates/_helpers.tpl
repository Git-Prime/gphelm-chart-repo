{{/* Creates a value that represents the full environment name */}}
{{- define "helpers.environment.fullName" }}
{{- if .Values.global.environment.modifierValue }}
{{- .Values.global.environment.parentName }}-{{ .Values.global.environment.modifierValue }}
{{- else }}
{{- .Values.global.environment.parentName }}
{{- end }}
{{- end }}

{{/* Creates a value for the right configuration server URL */}}
{{- define "helpers.configServerURL" }}
{{- if eq .Values.global.environment.parentName "production" }}
{{- "https://prod-config-server.gitprime-ops.com" }}
{{- else }}
{{- "https://config-server.gitprime-ops.com" }}
{{- end }}
{{- end }}
