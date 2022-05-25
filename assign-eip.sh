    #!/bin/bash
    #VM_NAME=`curl --header "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/hostname | cut -d "." -f 1`
    VM_NAME=""
    GCP_ZONE=$(basename `curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"`)
    GCP_REGION="${GCP_ZONE::-2}"
    # TODO: check if node already has label
    echo VM is $VM_NAME 
    ASSOCIATED=-1                                                                                                                                                                                                                                    
    CLUSTER=""
    RETRIES=10
    date
    echo "Attempting to get an address"
    ADDRESS=`gcloud beta compute addresses  list  --filter="labels.kubeip:$CLUSTER AND status=('RESERVED')" --regions $GCP_REGION | awk {'print $2'} | awk 'FNR == 2 {print}'`
    echo "Targeting $ADDRESS for $VM_NAME in $GCP_REGION and $GCP_ZONE"
    date -u
    echo "Attempting to delete access config"
    gcloud compute instances delete-access-config $VM_NAME --access-config-name="External NAT" --zone $GCP_ZONE
    date -u
    echo "delete access completed with $?"
    gcloud compute instances add-access-config $VM_NAME --access-config-name="External NAT" --address=$ADDRESS --zone $GCP_ZONE
    date -u
    echo "Add access completed with $?"
    ASSOCIATED=\$?
    if [[ \$ASSOCIATED != 0 ]];
        then
        echo "EIP Association failed"
        ASSOCIATED=1
        kubectl label node $VM_NAME kubeip=$ADDRESS
        else
        echo "EIP association successful"
    fi
   
