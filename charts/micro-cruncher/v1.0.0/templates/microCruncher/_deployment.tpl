{{- /* This represents a deployment that runs the micro cruncher jar and moves into different modes based on */}}
{{- /* environment variables and the like. */}}
{{- define "microCruncher.deploymentTemplate" }}
{{- $globalEnvironment := .Values.microCruncher.environment }}
{{- $environment := .templateData.environment }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitprime-mc-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  labels:
    app: gitprime-mc-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
spec:
  replicas: {{ .templateData.replicaCount }}
  selector:
    matchLabels:
      app: gitprime-mc-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: gitprime-mc-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
    spec:
      containers:
        - name: gitprime-mc-{{- template "helpers.environment.fullName" .}}-{{ .templateData.operationMode }}
          image: gp-docker.gitprime-ops.com/integrations/gitprime-micro-cruncher:{{ .Values.microCruncher.build.commitSHA }}
          imagePullPolicy: IfNotPresent
        {{- if .templateData.httpHost }}
          ports:
          - name: http
            containerPort: 8080
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: http
            initialDelaySeconds: 120
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthcheck
              port: http
            initialDelaySeconds: 30
            timeoutSeconds: 1
        {{- end }}
          env:
            - name: SYSTEM_ENV_PARENT
              value: {{ quote .Values.environment.parentName }}
            - name: SYSTEM_ENV_MODIFIER
              value: {{ quote .Values.environment.modifierValue }}
            - name: SYSTEM_ENV
              value: {{ include "helpers.environment.fullName" . | quote }}
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
          {{- if .templateData.javaOptions }}
            - name: JAVA_OPTS
              value: {{ quote .templateData.javaOptions }}
          {{- end }}
          {{- if .templateData.processorThreads }}
            - name: GP_PROCESSOR_THREADS
              value: {{ quote .templateData.processorThreads }}
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
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
{{- end }}
