{{/* Creates a value that represents a data pipeline deployment */}}
{{- define "helpers.dataPipeline.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .deployType }}
  labels:
    app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .deployType }}
spec:
  replicas: {{ .replicaCount }}
  selector:
    matchLabels:
      app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .deployType }}
  template:
    metadata:
      labels:
        app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .deployType }}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .deployType }}
              topologyKey: kubernetes.io/hostname
      containers:
        - name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-utility
          image: gp-docker.gitprime-ops.com/integrations/gitprime-data-pipeline:{{ .Values.dataPipeline.build.commitSHA }}
          imagePullPolicy: IfNotPresent
          env:
            - name: SYSTEM_ENV_PARENT
              value: {{ quote .Values.environment.parentName }}
            - name: SYSTEM_ENV_MODIFIER
              value: {{ quote .Values.environment.modifierValue }}
            - name: SYSTEM_ENV
              value: {{ include "helpers.environment.fullName" . | quote }}
          resources:
            requests:
              cpu: "1"
              memory: 5632Mi

      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
{{- end }}