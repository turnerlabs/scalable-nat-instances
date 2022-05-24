#!/bin/bash -x

return_code=1
tag="lower"

aws ec2 modify-instance-attribute --no-source-dest-check \
  --region "$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')" \
  --instance-id "$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)"

# attach 2 interfaces for maximal bandwidth
for i in {1..2}; do
    # retry attachment errors in case of contention
    while [ $return_code -ne 0 ]; do
        # get the first (random) available interface
        eni=$(aws ec2 describe-network-interfaces \
          --region "$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')" \
          --filters "Name=group-id,Values=${sg_id}" "Name=tag:half,Values=$tag" "Name=status,Values=available" \
          --query 'NetworkInterfaces[0].NetworkInterfaceId' | tr -d '"')

        # attach the ENI
        aws ec2 attach-network-interface \
          --region "$(/opt/aws/bin/ec2-metadata -z  | sed 's/placement: \(.*\).$/\1/')" \
          --instance-id "$(/opt/aws/bin/ec2-metadata -i | cut -d' ' -f2)" \
          --device-index $i \
          --network-interface-id $eni
        return_code=$?
    done
    return_code=1
    tag="upper"
done


# start SNAT
systemctl enable snat
systemctl start snat
