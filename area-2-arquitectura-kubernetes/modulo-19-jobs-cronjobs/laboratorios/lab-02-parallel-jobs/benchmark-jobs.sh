#!/bin/bash
# benchmark-jobs.sh - Benchmark de paralelismo en Jobs

echo "Benchmark de Jobs Paralelos"
echo "=============================="

# Test 1: Sin paralelismo
echo "Test 1: Parallelism = 1"
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: bench-p1
spec:
  completions: 10
  parallelism: 1
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "sleep 5 && echo Done"]
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete job/bench-p1 --timeout=300s
DURATION_P1=$(kubectl get job bench-p1 -o jsonpath='{.status.completionTime}' | date -u -f - +%s)
START_P1=$(kubectl get job bench-p1 -o jsonpath='{.status.startTime}' | date -u -f - +%s)
echo "Duración: $((DURATION_P1 - START_P1))s"
kubectl delete job bench-p1

# Test 2: Parallelism = 5
echo ""
echo "Test 2: Parallelism = 5"
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: bench-p5
spec:
  completions: 10
  parallelism: 5
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "sleep 5 && echo Done"]
      restartPolicy: Never
EOF

kubectl wait --for=condition=complete job/bench-p5 --timeout=300s
DURATION_P5=$(kubectl get job bench-p5 -o jsonpath='{.status.completionTime}' | date -u -f - +%s)
START_P5=$(kubectl get job bench-p5 -o jsonpath='{.status.startTime}' | date -u -f - +%s)
echo "Duración: $((DURATION_P5 - START_P5))s"
kubectl delete job bench-p5

echo ""
echo "=============================="
echo "Resumen:"
echo "Parallelism 1: ~50s (10 × 5s)"
echo "Parallelism 5: ~10s (2 grupos × 5s)"
echo "Speedup: ~5x"
