# RUL-AWS-DEPLOYMENT


We can not put our model code in lambda function script and run it. we need to install all dependencies. So we put our lambda function in a docker container with all dependencies inside this docker containes
and then we just deploy this docker container in aws.
We use uv in this deployment. 


we can test it locally using url before publish the docker image to aws = 'http://localhost:8000/2015-03-31/functions/function/invocations'


Solving dependencies:
lamda doesn't expect a virtual environment, so when we can't do just
RUN pip install uv
and we'll have to run uv export in our bash

in the docker image instead of doing uv sync now we do :
uv pip install --system -r ‹(uv export --format requirements-txt)
exporting all of the libraries in the requiremtn format. and we do uv pip isntall to install in the system

first i export all the ru

After testing locally using test.py script we then need to publish or docker image into ECR (Elastic container registry)

we create a repository inside ECR. So the new url will be the http request that makes the model run the prediction 


We are gonna use a publish.sh file 
After this we need to authenticate with aws accounts


For aws access we create a aim user attaching policies and granting permissions, AmazonEC2ContainerRegistryPowerUser, AWSLambda_FullAccess
after that password --region us-east-1 | \
> docker login --username AWS --password-stdin 064629264592.dkr.ecr.us-east-1.amazonaws.com
Login Succeeded


after pushing taging and creating the ecr v1, we need to go to lambda aws section and create a new function selecting the container image option


We test inside aws creating an event and using the json exmaple from test.py

Exposing lamnda function throught api gateaway

for that ge to the api gateaway in aws and we create a new one selcting a rest api. we create a resource, then we are going to create the method selecting post

After that we go to test and use the json example 

To expose th api we are going to deploy the api, creating a new url= https://aq8dv7o6dl.execute-api.us-east-1.amazonaws.com/predict

we use this url in test.py and run the script