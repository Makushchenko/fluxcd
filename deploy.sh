curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
k3d version
k3d cluster create demo \
  --servers 1 \
  --agents 3

helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system --create-namespace

helm get manifest flux-operator -n flux-system
kubectl get pod -n flux-system

kubectl apply -f fluxinstance.yaml
kubectl -n flux-system get fluxinstance
kubectl -n flux-system describe fluxinstance flux
kubectl -n flux-system logs deployment/flux-operator
kubectl -n flux-system events --for FluxInstance/flux
# --- Run kubectl delete to remove the FluxInstance resource and to uninstall Flux without affecting any Flux-managed workloads
kubectl -n flux-system delete FluxInstance/flux

kubectl create namespace kbot

# --- TELE_TOKEN secret (no secret in args; piped via stdin)
read -s TELE_TOKEN; echo
printf %s "$TELE_TOKEN" \
| kubectl -n kbot create secret generic kbot \
    --type=Opaque \
    --from-file=token=/dev/stdin \
    --dry-run=client -o yaml \
| kubectl apply -f -
kubectl get secret kbot -n kbot
kubectl describe secret kbot -n kbot

# --- GHCR dockerconfigjson secret (no creds in args; piped via stdin)
read -p "GHCR server [ghcr.io]: " SERVER; SERVER=${SERVER:-ghcr.io}
read -p "Email [ci@example.com]: " EMAIL; EMAIL=${EMAIL:-ci@example.com}
read -s -p "GHCR username: " GH_USER; echo
read -s -p "GHCR PAT: " GH_PAT; echo
AUTH_B64=$(printf "%s:%s" "$GH_USER" "$GH_PAT" | base64 | tr -d '\n')
printf '{"auths":{"%s":{"username":"%s","password":"%s","email":"%s","auth":"%s"}}}\n' \
  "$SERVER" "$GH_USER" "$GH_PAT" "$EMAIL" "$AUTH_B64" \
| kubectl -n kbot create secret generic ghcr-creds \
    --type=kubernetes.io/dockerconfigjson \
    --from-file=.dockerconfigjson=/dev/stdin \
    --dry-run=client -o yaml \
| kubectl apply -f -
kubectl get secret ghcr-creds -n kbot
kubectl describe secret ghcr-creds -n kbot

kubectl get pods -n flux-system -owide
kubectl get pods source-controller-7f4885bfbf-j89ck -n flux-system -owide
kubectl describe pod source-controller-7f4885bfbf-j89ck -n flux-system
kubectl get pods -n flux-system -o wide
kubectl get pods -n flux-system -l app=source-controller
kubectl logs source-controller-78b674c466-zkch7 -n flux-system -f
kubectl describe pod source-controller-78b674c466-zkch7 -n flux-system
kubectl -n flux-system get kustomization -o wide

# --- Check whether prune is enabled
kubectl -n flux-system get kustomization flux-system -o jsonpath='{.spec.prune}{"\n"}'

# Authenticate to GitHub Container Registry
echo $GH_PAT | docker login ghcr.io -u Makushchenko --password-stdin

kubectl get pods -n kbot
kubectl describe pods demo-d5df5c897-mbpj2 -n kbot
kubectl logs demo-d5df5c897-mbpj2 -n kbot -f

ghcr.io/makushchenko/kbot:v1.0.4-6e0844b-linux-amd64