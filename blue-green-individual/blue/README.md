
1) start minikube : ````minikube start --driver=docker````

2) Go to the downlaoded directory , and especially <blockquote>blue-green-individual</blockquote> folder and then type : ``kubectl apply -f ./blue ``

3) Check deployments : ``kubectl get deployments``

4) Check pods: ``kubectl get pods`` 

5) Directly open on the browser by typing :``minikube service deployment-demo``

6) directly type ``localhost:80``


