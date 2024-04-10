1) start minikube : ``minikube start --driver=docker``

2) Go tot he downlaoded directory , and especially blue-green-individual folder and then type : ``kubectl apply -f ./blue``

3) Go tot he downlaoded directory , and especially blue-green-individual folder and then type : ``kubectl apply -f ./green``

4) Check deployments : ``kubectl get deployments``

5) Check pods: ``kubectl get pods`` 

6) directly type ``localhost:80`` or ``localhost:8080`` --> it will redirects to ``localhost:80``

7)  Directly open on the browser by typing : ``minikube service deployment-demo`` or ``minikube service deployment-demo-green``
