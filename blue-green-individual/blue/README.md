
1) Start minikube : ````minikube start --driver=docker````

2) Go to the downlaoded directory , and especially <blockquote>blue-green-individual</blockquote> folder and then type : ``kubectl apply -f ./blue `` this command will run all the yaml files in this folder

3) Check deployments : ``kubectl get deployments``

4) Check pods: ``kubectl get pods`` 

5) Check Services: ``kubectl get services ``

6) Then port forward (your service)

   ``kubectl port-forward service/deployment-demo 8080:80``

7)  Directly open on the browser by typing :``localhost:8080``

