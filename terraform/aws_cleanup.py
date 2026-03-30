import boto3

def find_unattached_resources():
    ec2 = boto3.client('ec2', region_name='us-east-1')
    
    # 1. Поиск неиспользуемых Elastic IP
    eips = ec2.describe_addresses()
    for eip in eips['Addresses']:
        if 'InstanceId' not in eip:
            print(f"Найдено неиспользуемое Elastic IP: {eip['PublicIp']}")

    # 2. Поиск старых Snapshot-ов
    snapshots = ec2.describe_snapshots(OwnerIds=['self'])
    for snap in snapshots['Snapshots']:
        print(f"Найден Snapshot: {snap['SnapshotId']} от {snap['StartTime']}")

    # 3. Поиск неиспользуемых EBS Volumes
    volumes = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])
    for vol in volumes['Volumes']:
        print(f"Найден свободный диск (Volume): {vol['VolumeId']} ({vol['Size']}GB)")

if __name__ == "__main__":
    find_unattached_resources()