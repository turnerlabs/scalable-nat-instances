#!/bin/bash -x

return_code=1
tags=${tags}

region=$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')
instance_id=$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)

aws ec2 modify-instance-attribute --no-source-dest-check \
  --region "$region" \
  --instance-id "$instance_id"

# attach one interface for each route
for i in {1..${routes_count}}; do
    # retry attachment errors in case of contention
    while (( return_code )); do
        # get the first (random) available interface
        eni=$(aws ec2 describe-network-interfaces \
          --region "$region" \
          --filters "Name=group-id,Values=${sg_id}" "Name=tag:route,Values=$${tags[i-1]}" "Name=status,Values=available" \
          --query 'NetworkInterfaces[0].NetworkInterfaceId' | tr -d '"')

        # attach the ENI
        aws ec2 attach-network-interface \
          --region "$region" \
          --instance-id "$instance_id" \
          --device-index $i \
          --network-interface-id $eni
        return_code=$?
    done
    return_code=1
done


# start SNAT
systemctl enable snat
systemctl start snat
