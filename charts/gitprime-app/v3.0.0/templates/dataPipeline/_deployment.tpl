{{- /* This represents a deployment that runs the main Data Pipeline jar and moves into different modes based on */}}
{{- /* environment variables and the like. */}}
{{- define "dataPipeline.deploymentTemplate" }}
{{- $globalEnvironment := .Values.dataPipeline.environment }}
{{- $environment := .templateData.environment }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  labels:
    app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
spec:
  replicas: {{ .templateData.replicaCount }}
  selector:
    matchLabels:
      app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
    spec:
      containers:
        - name: gitprime-dp-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
          image: gp-docker.gitprime-ops.com/cloud/gitprime-data-pipeline-app:{{ .Values.dataPipeline.build.commitSHA }}
          imagePullPolicy: IfNotPresent
          env:
            - name: SYSTEM_ENV_PARENT
              value: {{ quote .Values.environment.parentName }}
            - name: SYSTEM_ENV_MODIFIER
              value: {{ quote .Values.environment.modifierValue }}
            - name: SYSTEM_ENV
              value: {{ include "helpers.environment.fullName" . | quote }}
            - name: DATADOG_ENABLED
              value: {{ quote .Values.dataPipeline.datadog.enabled }}
            - name: SYSTEM_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: SYSTEM_OPERATION_MODE
              value: {{ quote .templateData.operationMode }}
            - name: SYSTEM_CONFIG_SERVER_URL
              value: {{ include "helpers.configServerURL" . }}
            - name: GP_LOG_LEVEL
              value: {{ quote .templateData.logLevel | default "INFO" | lower }}
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
          {{- if .templateData.javaOptions }}
            - name: JAVA_OPTS
              value: {{ quote .templateData.javaOptions }}
          {{- end }}
          {{- if .templateData.newListeners }}
            - name: GP_NEW_LISTENERS
              value: {{ quote .templateData.newListeners }}
          {{- end}}
          {{- if .templateData.newThreadsPerListener }}
            - name: GP_NEW_WORKERS_PER_LISTENER
              value: {{ quote .templateData.newThreadsPerListener }}
          {{- end}}
          {{- if .templateData.newMaxCommitCount }}
            - name: GP_NEW_MAX_COMMIT_COUNT
              value: {{ quote .templateData.newMaxCommitCount }}
          {{- end}}
          {{- if .templateData.incrListeners }}
            - name: GP_INCREMENTAL_LISTENERS
              value: {{ quote .templateData.incrListeners }}
          {{- end}}
          {{- if .templateData.incrThreadsPerListener }}
            - name: GP_INCREMENTAL_WORKERS_PER_LISTENER
              value: {{ quote .templateData.incrThreadsPerListener }}
          {{- end}}
          {{- if .templateData.incrMaxCommitCount }}
            - name: GP_INCREMENTAL_COMMIT_COUNT
              value: {{ quote .templateData.incrMaxCommitCount }}
          {{- end}}
          {{- if .templateData.aodListeners }}
            - name: GP_AOD_LISTENERS
              value: {{ quote .templateData.aodListeners }}
          {{- end}}
          {{- if .templateData.incrThreadsPerListener }}
            - name: GP_AOD_WORKERS_PER_LISTENER
              value: {{ quote .templateData.incrThreadsPerListener }}
          {{- end}}
          {{- if .templateData.ticketListeners }}
            - name: GP_TICKET_LISTENERS
              value: {{ quote .templateData.ticketListeners }}
          {{- end}}
          {{- if .templateData.ticketThreadsPerListener }}
            - name: GP_TICKET_WORKERS_PER_LISTENERS
              value: {{ quote .templateData.ticketThreadsPerListener }}
          {{- end}}
          {{- if .templateData.incrMaxCommitCount }}
            - name: GP_INCREMENTAL_COMMIT_COUNT
              value: {{ quote .templateData.incrMaxCommitCount }}
          {{- end}}
          {{- range $globalEnvironment }}
            - name: {{ .name }}
              value: {{ .value | quote }}
          {{- end }}
          {{- range $environment }}
            - name: {{ .name }}
              value: {{ .value | quote }}
          {{- end }}
          resources:
          {{- if .templateData.resources }}
          {{- if or (.templateData.resources.requests.cpu) (.templateData.resources.requests.memory) }}
            requests:
            {{- if .templateData.resources.requests.cpu }}
              cpu: {{ quote .templateData.resources.requests.cpu }}
            {{- end }}
            {{- if .templateData.resources.requests.memory }}
              memory: {{ .templateData.resources.requests.memory }}
            {{- end }}
          {{- end }}
          {{- if or (.templateData.resources.limits.cpu) (.templateData.resources.limits.memory) }}
            limits:
            {{- if .templateData.resources.limits.cpu }}
              cpu: {{ quote .templateData.resources.limits.cpu }}
            {{- end }}
            {{- if .templateData.resources.limits.memory }}
              memory: {{ .templateData.resources.limits.memory }}
            {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.dataPipeline.volumes.enableLocalMount }}
          volumeMounts:
            - mountPath: {{ quote .Values.dataPipeline.volumes.podMountDirectory }}
              name: repository-storage-volume
          {{- end }}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
          - name: ndots
          value: "1"
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      {{- if .Values.dataPipeline.volumes.enableLocalMount }}
      volumes:
      - hostPath:
          path: {{ quote .Values.dataPipeline.volumes.nodeMountDirectory }}
          type: DirectoryOrCreate
        name: repository-storage-volume
      {{- end }}
{{- end }}
