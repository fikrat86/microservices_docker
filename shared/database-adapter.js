/**
 * DynamoDB Data Access Layer
 * Provides abstraction for DynamoDB operations with fallback to JSON files
 */

const AWS = require('aws-sdk')

// Configure AWS SDK
const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1'
})

/**
 * Database adapter that works with both DynamoDB and JSON files
 */
class DatabaseAdapter {
  constructor (tableName, jsonData = null, primaryKey = 'id') {
    this.tableName = tableName
    this.jsonData = jsonData
    this.primaryKey = primaryKey
    this.useDynamoDB = process.env.USE_DYNAMODB === 'true'
    
    console.log(`📊 Database Mode: ${this.useDynamoDB ? 'DynamoDB' : 'JSON File'}`)
    if (this.useDynamoDB) {
      console.log(`📦 DynamoDB Table: ${this.tableName}`)
    }
  }

  /**
   * Get all items
   */
  async getAll () {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName
        }
        const result = await dynamodb.scan(params).promise()
        return result.Items || []
      } catch (error) {
        console.error('DynamoDB scan error:', error)
        throw error
      }
    } else {
      return this.jsonData || []
    }
  }

  /**
   * Get item by ID
   */
  async getById (id) {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          Key: {
            [this.primaryKey]: id.toString()
          }
        }
        const result = await dynamodb.get(params).promise()
        return result.Item || null
      } catch (error) {
        console.error('DynamoDB get error:', error)
        throw error
      }
    } else {
      const items = this.jsonData || []
      return items.find(item => item.id.toString() === id.toString()) || null
    }
  }

  /**
   * Query items by secondary index
   */
  async queryByIndex (indexName, keyName, keyValue) {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          IndexName: indexName,
          KeyConditionExpression: `#key = :value`,
          ExpressionAttributeNames: {
            '#key': keyName
          },
          ExpressionAttributeValues: {
            ':value': keyValue.toString()
          }
        }
        const result = await dynamodb.query(params).promise()
        return result.Items || []
      } catch (error) {
        console.error('DynamoDB query error:', error)
        throw error
      }
    } else {
      const items = this.jsonData || []
      return items.filter(item => item[keyName]?.toString() === keyValue.toString())
    }
  }

  /**
   * Create new item
   */
  async create (item) {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          Item: item
        }
        await dynamodb.put(params).promise()
        return item
      } catch (error) {
        console.error('DynamoDB put error:', error)
        throw error
      }
    } else {
      // For JSON mode, just return the item (read-only)
      console.warn('⚠️  JSON mode is read-only, cannot create items')
      return item
    }
  }

  /**
   * Update existing item
   */
  async update (id, updates) {
    if (this.useDynamoDB) {
      try {
        // Build update expression
        const updateExpressions = []
        const expressionAttributeNames = {}
        const expressionAttributeValues = {}
        
        Object.keys(updates).forEach((key, index) => {
          const attrName = `#attr${index}`
          const attrValue = `:val${index}`
          updateExpressions.push(`${attrName} = ${attrValue}`)
          expressionAttributeNames[attrName] = key
          expressionAttributeValues[attrValue] = updates[key]
        })
        
        const params = {
          TableName: this.tableName,
          Key: {
            [this.primaryKey]: id.toString()
          },
          UpdateExpression: `SET ${updateExpressions.join(', ')}`,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues,
          ReturnValues: 'ALL_NEW'
        }
        
        const result = await dynamodb.update(params).promise()
        return result.Attributes
      } catch (error) {
        console.error('DynamoDB update error:', error)
        throw error
      }
    } else {
      console.warn('⚠️  JSON mode is read-only, cannot update items')
      const item = await this.getById(id)
      return { ...item, ...updates }
    }
  }

  /**
   * Delete item
   */
  async delete (id) {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          Key: {
            [this.primaryKey]: id.toString()
          }
        }
        await dynamodb.delete(params).promise()
        return true
      } catch (error) {
        console.error('DynamoDB delete error:', error)
        throw error
      }
    } else {
      console.warn('⚠️  JSON mode is read-only, cannot delete items')
      return false
    }
  }

  /**
   * Count items
   */
  async count () {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          Select: 'COUNT'
        }
        const result = await dynamodb.scan(params).promise()
        return result.Count || 0
      } catch (error) {
        console.error('DynamoDB count error:', error)
        throw error
      }
    } else {
      return (this.jsonData || []).length
    }
  }

  /**
   * Health check
   */
  async healthCheck () {
    if (this.useDynamoDB) {
      try {
        const params = {
          TableName: this.tableName,
          Limit: 1
        }
        await dynamodb.scan(params).promise()
        return { status: 'healthy', mode: 'dynamodb', table: this.tableName }
      } catch (error) {
        return { status: 'unhealthy', mode: 'dynamodb', error: error.message }
      }
    } else {
      return { status: 'healthy', mode: 'json', items: (this.jsonData || []).length }
    }
  }
}

module.exports = DatabaseAdapter
