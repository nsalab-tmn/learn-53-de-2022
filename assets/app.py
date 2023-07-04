import sys
import os
import yaml
import redis
import json
import requests
from flask import Flask, request, render_template, jsonify
from azure.cosmos import CosmosClient, PartitionKey, exceptions
from uuid import uuid4
import hashlib


app = Flask(__name__)


def check_md5():
    hash_md5 = hashlib.md5()
    try:
        with open('./app.py', "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
    except:
        pass
    return hash_md5.hexdigest()

def test_redis():
    data = {'redis_payload': 'Not found', 'status': 'Successfully connected'}
    try:
        conn = redis.StrictRedis(host=env_variables['redis']['host'], port=env_variables['redis']['port'],
                                 password=env_variables['redis']['secret'], ssl=True, db=0)
    except:
        data['status'] = "Connection error"
    try:
        conn.set('var', str(uuid4()))
    except:
        data['status'] = "Connection error"
    try:
        data['redis_payload'] = conn.get('var').decode('utf8')
    except:
        data['status'] = "Connection error"
    return data


def test_cosmos():
    out_data = {'db_payload': {'id': 'Not found'},
                'status': 'Successfully connected'}
    try:
        client = CosmosClient(
            env_variables['cosmos']['host'], credential=env_variables['cosmos']['secret'])
    except:
        out_data['status'] = "Connection error"

    try:
        database = client.get_database_client(
            env_variables['cosmos']['db_name'])
    except:
        out_data['status'] = "Connection error"

    try:
        container = database.get_container_client(
            env_variables['cosmos']['container'])
    except:
        out_data['status'] = "Connection error"

    try:
        container.upsert_item(
            {
                'id': '{0}'.format(str(uuid4())),
                env_variables['cosmos']['partition_key']: 'iPhone 13 Pro',
            }
        )

    except:
        out_data['status'] = "Connection error"
    try:

        for item in container.query_items(
                query='SELECT * FROM c OFFSET 0 LIMIT 1',
                enable_cross_partition_query=True):

            try:
                out_data['db_payload']['id'] = item['id']
            except:
                out_data['db_payload']['id'] = 'Not found'
                out_data['status'] = "Connection error"

    except:
        out_data['status'] = "Connection error"

    return out_data


@app.route('/health')
def health():
    status = "Healthy"
    retcode = 200
    return status, retcode

def health_old():
    status = ""
    retcode = 200
    redis_health = test_redis()
    cosmos_health = test_cosmos()
    if(redis_health['status'] == "Successfully connected" and cosmos_health['status'] == "Successfully connected"):
        status = "Healthy"
    else:
        status = "Unhealthy"
        retcode = 500
    return jsonify({'health': status}), retcode


@app.route('/')
def main_page():
    return jsonify(str(uuid4()))


@app.route('/status')
def status():
    redis_data = test_redis()
    cosmos_data = test_cosmos()
    return(jsonify(
        {
            'redis': redis_data['status'],
            'redis_payload': redis_data['redis_payload'],
            'cosmos': cosmos_data['status'],
            'cosmos_payload': cosmos_data['db_payload']['id']
        }
    )
    )


@app.route('/full-status')
def full_status():
    status = {'server': {},
              'redis': {},
              'cosmos_db': {},
              'instance': {'scaling': None,
                           'private_ip': None,
                           'vmSize': None,
                           'subnet': None,
                           'osType': None,
                           'location': None},
                'md5sum': None
              }

    try:
        req = requests.get(
            "http://169.254.169.254/metadata/instance?api-version=2021-02-01", headers={'Metadata': 'true'}, timeout=0.5)
        metadata = json.loads(req.text)
        status['instance']['private_ip'] = metadata['network']['interface'][0]['ipv4']['ipAddress'][0]['privateIpAddress']
        status['instance']['subnet'] = metadata['network']['interface'][0]['ipv4']['subnet'][0]['address'] + '/' + metadata['network']['interface'][0]['ipv4']['subnet'][0]['prefix']
        status['instance']['vmSize'] = metadata['compute']['vmSize']
        status['instance']['location'] = metadata['compute']['location']
        if 'vmScaleSetName' in metadata['compute']:
            status['instance']['scaling'] = metadata['compute']['vmScaleSetName']
    except:
        status['instance']['summary'] = "Not a instance"


    status['md5sum'] = check_md5()
    status['instance']['osType'] = os.uname()


    status['server']['ip'] = env_variables['server']['ip_address']
    status['server']['internal_port'] = env_variables['server']['port']

    status['redis']['host'] = env_variables['redis']['host']
    status['redis']['port'] = env_variables['redis']['port']

    redis_func = test_redis()

    if(redis_func['status'] == "Successfully connected"):
        status['redis']['functionality'] = 'Working'
    else:
        status['redis']['functionality'] = 'Not Working'

    status['cosmos_db']['host'] = env_variables['cosmos']['host']
    status['cosmos_db']['database_name'] = env_variables['cosmos']['db_name']
    status['cosmos_db']['container'] = env_variables['cosmos']['container']
    status['cosmos_db']['container'] = env_variables['cosmos']['partition_key']

    cosmos_func = test_cosmos()

    if(cosmos_func['status'] == "Successfully connected"):
        status['cosmos_db']['functionality'] = 'Working'
    else:
        status['cosmos_db']['functionality'] = 'Not Working'

    return status


if __name__ == '__main__':

    print(os.getcwd())
    try:
        # VS Code понимает несколько некорректно, для прода надо починить и писать тут './env.yaml'
        with open("./env.yaml", 'r') as file:
            env_variables = yaml.safe_load(file)
    except:
        print("Check env.yaml")
        sys.exit(1)

    app.run(host=env_variables['server']['ip_address'],
            port=env_variables['server']['port'], debug=False)
