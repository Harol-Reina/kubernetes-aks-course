# Agent Memory - k8s-course-module-builder

## Key Patterns Confirmed

### YAML File Header Convention (from lab-02, lab-05)
Every YAML file must start with a comment block in this exact order:
```
# Ejercicio N: Title - Subtitle
# Uso: kubectl apply -f filename.yaml
#
# Descripcion:
#   ...explanation...
#   - key: value  → explanation
#
# Namespace: lab-xxx
```

### README.md Lab Pattern (file-based, not inline YAML)
- Use `cat filename.yaml` immediately before each `kubectl apply -f filename.yaml`
- Never include inline YAML blocks inside README.md for labs that have separate YAML files
- Include a YAML file table near the top (after the intro, before exercises)
- Table columns: Archivo | Estrategia/Ejercicio | Descripcion

### cleanup.sh Pattern (from lab-02, confirmed in lab-05)
Full pattern with: shebang, set -e, color vars (RED/GREEN/YELLOW/NC), header comment block,
`delete_resource()` function with namespace param, sections for each resource type,
namespace deletion block, context restore, verification check, summary of deleted resources.

### SETUP.md Pattern (from lab-02, confirmed in lab-05)
Sections: Conocimientos Previos, Herramientas Necesarias, Verificacion del Entorno
(with commands + expected output), Archivos YAML Incluidos (table), preparation commands.

### Namespace Convention
- lab-02: `lab-rolling-updates`
- lab-03: `lab-rollback`
- lab-05: `lab-estrategias`

### Resource Requests/Limits
Always include in production YAML examples:
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```
Failing/demo containers can use smaller: requests 32Mi/50m, limits 64Mi/100m.

### Named Ports
Use `name: http` on containerPort and reference it in targetPort:
```yaml
ports:
- name: http
  containerPort: 80
# In service:
  targetPort: http
```

## Critical Mistakes to Avoid
- NEVER use the Write tool with a file path string as the content value -- this overwrites the file with just the path. Always write actual file content.
- Always backup README.md before rewriting: copy to README.md.backup first.

## Module Status Notes
- area-2 modulo-07: labs 01-07, 08 complete with separate YAML files
- lab-07-pausar-resume (troubleshooting): converted from inline YAML to 8 separate files (Feb 2026)
  Namespace: lab-troubleshooting. Files: broken-image, broken-readiness, oom-deployment,
  stuck-rollout, selector-mismatch, selector-mismatch-fixed, permission-issue, permission-issue-fixed.
- lab-05-blue-green: converted from inline YAML to separate files (10 YAML files)
- lab-06-canary (best practices): converted from inline YAML to 9 separate files
  Namespace: lab-production. Resources: webapp-prod, webapp-with-config, webapp-service,
  webapp-hpa, webapp-pdb x2, webapp-network-policy, webapp-config (ConfigMap)
  Optional resources (require addons): webapp-ingress, webapp-servicemonitor
  Note: Secrets stay imperative (kubectl create secret), never in YAML files.
- lab-08-troubleshooting: converted from inline YAML to separate files (8 YAML files)
  Namespace: ecommerce-prod. Integrator lab covering full e-commerce stack.
  Note: Secrets stay imperative (kubectl create secret), never in YAML files.

### Integrator Lab Pattern (lab-08)
- YAML file header uses "Parte N - Paso M:" prefix instead of "Ejercicio N:"
- Multi-document YAML (---) used for Deployment+Service pairs in backend files
- cleanup.sh for namespace-scoped labs: delete namespace directly (not individual resources)
  then verify NS_EXISTS == 0, also kill port-forward processes with pgrep
- SETUP.md includes note explaining why Secrets are NOT in YAML files (security)

## See Also
- patterns.md (detailed patterns)
