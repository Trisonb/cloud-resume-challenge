import json
import boto3
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['TABLE_NAME']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    logger.info(f"Full event: {json.dumps(event)}")  # Log the entire event
    try:
        # For proxy integration, event['body'] should contain the payload
        if 'body' in event and event['body']:
            logger.info("Parsing body from event")
            body = json.loads(event['body'])
            user = body.get('user', 'visitor')
        else:
            logger.info("No body in event, using direct user field as fallback")
            user = event.get('user', 'visitor')  # Fallback for direct invocation
        logger.info(f"User: {user}")

        # Get current count
        logger.info("Fetching current count from DynamoDB")
        response = table.get_item(Key={'user': user})
        logger.info(f"DynamoDB get_item response: {response}")
        count = response.get('Item', {}).get('count', 0)
        logger.info(f"Current count: {count}")

        # Increment count
        count += 1
        logger.info("Incrementing count and saving to DynamoDB")
        table.put_item(Item={'user': user, 'count': count})
        logger.info("Count saved successfully")

        # Return response for proxy integration
        response_body = {
            'message': f'Hello {user}! You have visited this page {count} times.'
        }
        logger.info(f"Returning response: {response_body}")
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps(response_body)
        }
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': f'Error: {str(e)}'})
        }