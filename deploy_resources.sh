# The script will be deploying all kubernetes resources.

# Default Environment Variables
NAMESPACE_NAME="${NAMESPACE_NAME:-default}"
STORAGEC_CLASS_NAME="${STORAGEC_CLASS_NAME:-manual}"
CUSTOM_SERVICE_ACCOUNT_ENABLE=${CUSTOM_SERVICE_ACCOUNT_ENABLE:-false}
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-default}"
MONGODB_IMAGE_NAME="${MONGODB_IMAGE_NAME:-docker.io\/bitnami\/mongodb\:4.4}"
RABBITMQ_IMAGE_NAME="${RABBITMQ_IMAGE_NAME:-docker.io\/bitnami\/rabbitmq\:3.9}"
CORE_IMAGE_NAME="${CORE_IMAGE_NAME:-crestsystems\/cloudexchange\:core-3.4-debug-6}"
UI_IMAGE_NAME="${UI_IMAGE_NAME:-crestsystems\/cloudexchange\:ui-3.4-debug-1}"

# Replacing namespace name in all k8s resource files.
find ./mongo/*.yaml -type f -exec sed -i "s/<NAMESPACE_NAME>/$NAMESPACE_NAME/g" {} \;
find ./rabbit/*.yaml -type f -exec sed -i "s/<NAMESPACE_NAME>/$NAMESPACE_NAME/g" {} \;
find ./core/*.yaml -type f -exec sed -i "s/<NAMESPACE_NAME>/$NAMESPACE_NAME/g" {} \;
find ./ui/*.yaml -type f -exec sed -i "s/<NAMESPACE_NAME>/$NAMESPACE_NAME/g" {} \;

if [ $CUSTOM_SERVICE_ACCOUNT_ENABLE == "true" ]; then
    # Replacing service account name in all k8s resource files.
    find ./mongo/*.yaml -type f -exec sed -i "s/<SERVICEACCOUNT_NAME>/$SERVICE_ACCOUNT_NAME/g" {} \;
    find ./rabbit/*.yaml -type f -exec sed -i "s/<SERVICEACCOUNT_NAME>/$SERVICE_ACCOUNT_NAME/g" {} \;
    find ./core/*.yaml -type f -exec sed -i "s/<SERVICEACCOUNT_NAME>/$SERVICE_ACCOUNT_NAME/g" {} \;
    find ./ui/*.yaml -type f -exec sed -i "s/<SERVICEACCOUNT_NAME>/$SERVICE_ACCOUNT_NAME/g" {} \;
fi

# Replacing storage class name in all k8s resource files.
find ./mongo/*.yaml -type f -exec sed -i "s/<STORAGE_CLASS>/$STORAGEC_CLASS_NAME/g" {} \;
find ./rabbit/*.yaml -type f -exec sed -i "s/<STORAGE_CLASS>/$STORAGEC_CLASS_NAME/g" {} \;

# Replacing container image name in all k8s resource files.
find ./mongo/*.yaml -type f -exec sed -i "s/<MONGODB_IMAGE_NAME>/$MONGODB_IMAGE_NAME/g" {} \;
find ./rabbit/*.yaml -type f -exec sed -i "s/<RABBITMQ_IMAGE_NAME>/$RABBITMQ_IMAGE_NAME/g" {} \;
find ./core/*.yaml -type f -exec sed -i "s/<CORE_IMAGE_NAME>/$CORE_IMAGE_NAME/g" {} \;
find ./ui/*.yaml -type f -exec sed -i "s/<UI_IMAGE_NAME>/$UI_IMAGE_NAME/g" {} \;

# MongoDB
echo "-----------------------------------"
echo "Deploying MongoDB"
echo "-----------------------------------"
kubectl apply -f mongo/

# Rabbit MQ
echo "-----------------------------------"
echo "Deploying RabbitMQ"
echo "-----------------------------------"
kubectl apply -f rabbit/

# Core
echo "-----------------------------------"
echo "Deploying Core"
echo "-----------------------------------"
kubectl apply -f core/

# UI
echo "-----------------------------------"
echo "Deploying UI"
echo "-----------------------------------"
kubectl apply -f ui/