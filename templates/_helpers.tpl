{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.name" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Kubernetes labels
*/}}
{{- define "resource.labels.commonLabels" -}}
helm.sh/chart: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Labels to use on deploy.spec.selector.matchLabels and svc.spec.selector
*/}}
{{- define "resource.labels.commonMatchLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
{{- define "namespace.name" -}}
    {{- if .Values.namespace }}
        {{- .Values.namespace }}
    {{- else }}
        {{- .Release.Namespace }}
    {{- end }}
{{- end -}}

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either Chart.Name-container-serviceaccount if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "serviceAccountName.name" -}}
    {{- if .Values.serviceAccount.create -}}
        {{- default (printf "%s-serviceaccount" .Chart.Name) (print .Values.serviceAccount.name) -}}
    {{- else -}}
        {{- default "default" (print .Values.serviceAccount.name) -}}
    {{- end -}}
{{- end -}}

