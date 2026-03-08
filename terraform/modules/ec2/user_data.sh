#!/bin/bash
set -e

# CloudWatch Logs agent setup
cat > /opt/cloudwatch-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${cloudwatch_group}",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/docker",
            "log_group_name": "${cloudwatch_group}",
            "log_stream_name": "{instance_id}-docker"
          }
        ]
      }
    }
  }
}
EOF

# Install CloudWatch agent
yum update -y
yum install -y amazon-cloudwatch-agent amazon-ssm-agent

# Start services
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Pull and run Docker image
docker pull ${docker_image}
docker run -d \
  --name app \
  --restart always \
  -p ${app_port}:${app_port} \
  -e ENVIRONMENT=${environment} \
  -e PROJECT=${project_name} \
  --log-driver awslogs \
  --log-opt awslogs-group=${cloudwatch_group} \
  --log-opt awslogs-stream={instance_id} \
  ${docker_image}

# Health check
sleep 10
curl -f http://localhost:${app_port}/health || exit 1

echo "✅ Application startup completed"
