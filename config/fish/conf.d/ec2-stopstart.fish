function aws-ec2-stopstart --argument ids --description "Stop-start ec2 instance, blocking until the process is completed"
    set id "--instance-ids=$ids"
    aws ec2 stop-instances $id
    sleep 5
    aws ec2 wait instance-stopped $id
    sleep 5
    aws ec2 start-instances $id
    sleep 5
    aws ec2 wait instance-running $id
end
