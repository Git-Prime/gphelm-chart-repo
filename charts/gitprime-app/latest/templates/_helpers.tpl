{{/* Creates a value that represents the full environment name */}}
{{- define "helpers.environment.fullName" }}
{{- if .Values.environment.modifierValue }}
{{- .Values.environment.parentName }}-{{ .Values.environment.modifierValue }}
{{- else }}
{{- .Values.environment.parentName }}
{{- end }}
{{- end }}
