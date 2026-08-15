{{- define "kubequest-app.name" -}}
kubequest-app
{{- end -}}

{{- define "kubequest-app.labels" -}}
app.kubernetes.io/name: {{ include "kubequest-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: kubequest
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "kubequest-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubequest-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "kubequest-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- .Values.serviceAccount.name | default (include "kubequest-app.name" .) -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end -}}
