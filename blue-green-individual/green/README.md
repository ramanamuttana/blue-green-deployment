1) start minikube : minikube start --driver=docker

2) Go tot he downlaoded directory , and especially blue-green-individual folder and then type : kubectl apply -f ./green

3) Check deployments : kubectl get deployments

4) Check pods: kubectl get pods 

5) Directly open on the browser by typing :minikube service deployment-demo-green

6) directly type localhost:8080 
