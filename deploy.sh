#! /bin/bash

# Create lambda layer dir
# docker run -v "$PWD":/var/task "public.ecr.aws/sam/build-python3.9" /bin/sh -c "pip install -r requirements.txt -t python/lib/python3.9/site-packages/; exit"
# cp -r ./src/antarctica_lambda_modules python/lib/python3.9/site-packages/
# zip -r antarctica_lambda_modules.zip python > /dev/null
# rm -rf ./python
# aws lambda publish-layer-version --layer-name mypythonlibs --description "antarctica-python-modules" --zip-file fileb://antarctica_lambda_modules.zip --compatible-runtimes "python3.9"
# rm antarctica_lambda_modules.zip


# Deploy infrastructure
cd infra
terraform fmt
terraform plan -var-file=env/beta.tfvars
terraform apply -var-file=env/beta.tfvars

# Remove lambda layer zip

