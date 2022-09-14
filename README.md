# Deploy Netskope Cloud Exchange using K8s

The end goal is to deploy Netskope Cloud Exchange(CE) on the Container Orchestration platforms.

## Prerequisite
- `kubectl` must be installed on machine.

## Step-by-step Deployment
### Step 1
- Export following variable if you want to override default value, to check default value check the shell script.

```
export NAMESPACE_NAME=
export CUSTOM_SERVICE_ACCOUNT_ENABLE=
export SERVICE_ACCOUNT_NAME=
export STORAGEC_CLASS_NAME=
export MONGODB_IMAGE_NAME=
export RABBITMQ_IMAGE_NAME=
export CORE_IMAGE_NAME=
export UI_IMAGE_NAME=
```

### Step 2
Create the following secrets by running the below commands.

- Create the below secrets for MongoDB.
```
kubectl create secret generic netskope-ce-mongodb \
  --from-literal=mongodb-replica-set-key=<key> \
  --from-literal=mongodb-root-username=<username> \
  --from-literal=mongodb-root-password=<password> \
  --from-literal=mongodb-root-escaped-password=<escaped-password> -n $NAMESPACE_NAME
```
**Note:** We need to pass escaped password in mongodb connection string like, if we have password such as `admin@123` then we need to escape special character in password, after escaped that password will look like `admin%40123`. 

- Create the below secrets for RabbitMQ.
```
kubectl create secret generic netskope-ce-rabbitmq \
  --from-literal=rabbitmq-erl-cookie=<cookie> \
  --from-literal=rabbitmq-password=<password> -n $NAMESPACE_NAME
```

- Create the below secrets for Core.
```
kubectl create secret generic netskope-ce-core \
  --from-literal=analytics-token=<analytics-token> \
  --from-literal=jwt-secret=<jwt-secret> -n $NAMESPACE_NAME
```

- Create the below secrets for UI
```
kubectl create secret generic netskope-ce-cert \
--from-file=cte_cert.crt=<cert-file-name> \
--from-file=cte_cert_key.key=<cert-private-key-name> -n $NAMESPACE_NAME
```
**Note:** If you are using your existing SSL Certificates then Certificate file name must be `cte_cert.crt` and Certificate Private Key name must be `crte_cert_key.key` and must create the above secret.

### Step  3
Go to the root level where all the deployment files are available.

Deploy all k8s resources by running the below shell script.

**Note:** All the containers will be running with `non-root` user.
```
sh deploy_resources.sh
```

Wait for all resources to be deployed, check status of resources by running the below.
```
kubectl get all
```

### Step 4
To check or verify deployment of product locally, we need to forward the port of the UI service.
```
kubectl port-forward service/netskope-ce-ui 8080:80
```