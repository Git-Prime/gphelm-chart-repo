{{- /* This represents a deployment that runs the main Reporting Pipeline component and moves into different modes based on */}}
{{- /* environment variables and the like. */}}
{{- define "reportingPipeline.deploymentTemplate" }}
{{- $globalEnvironment := .Values.reportingPipeline.environment }}
{{- $environment := .templateData.environment }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitprime-rpt-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  labels:
    app: gitprime-rpt-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
spec:
  replicas: {{ .templateData.replicaCount }}
  selector:
    matchLabels:
      app: gitprime-rpt-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app: gitprime-rpt-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
    spec:
      containers:
        - name: gitprime-rpt-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
          image: gp-docker.gitprime-ops.com/cloud/gitprime-rpt-reporting-app:{{ .Values.reportingPipeline.build.commitSHA }}
          imagePullPolicy: IfNotPresent
        {{- if .templateData.httpHost }}
          ports:
          - name: http
            containerPort: 8080
        {{- end }}
          env:
            - name: SYSTEM_ENV_PARENT
              value: {{ quote .Values.environment.parentName }}
            - name: SYSTEM_ENV_MODIFIER
              value: {{ quote .Values.environment.modifierValue }}
            - name: SYSTEM_ENV
              value: {{ include "helpers.environment.fullName" . | quote }}
            - name: DATADOG_ENABLED
              value: {{ quote .Values.reportingPipeline.datadog.enabled }}
            - name: DNS_CONFIG_NDOTS
              value: {{ quote .Values.reportingPipeline.dns.ndots }}
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
          {{- if .Values.reportingPipeline.volumes.enableLocalMount }}
          volumeMounts:
            - mountPath: {{ quote .Values.reportingPipeline.volumes.podMountDirectory }}
              name: repository-storage-volume
          {{- end }}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
          - name: ndots
            value: "2"
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      {{- if .Values.reportingPipeline.volumes.enableLocalMount }}
      volumes:
      - hostPath:
          path: {{ quote .Values.reportingPipeline.volumes.nodeMountDirectory }}
          type: DirectoryOrCreate
        name: repository-storage-volume
      {{- end }}
{{- end }}
