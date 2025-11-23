#!/usr/bin/env node

/**
 * Data Migration Script: db.json to DynamoDB
 * Migrates existing JSON data files to DynamoDB tables
 */

const AWS = require('aws-sdk')
const fs = require('fs')
const path = require('path')

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1'
})

const dynamodb = new AWS.DynamoDB.DocumentClient()

// Table names from environment or defaults
const USERS_TABLE = process.env.DYNAMODB_USERS_TABLE || 'forum-microservices-users-dev'
const THREADS_TABLE = process.env.DYNAMODB_THREADS_TABLE || 'forum-microservices-threads-dev'
const POSTS_TABLE = process.env.DYNAMODB_POSTS_TABLE || 'forum-microservices-posts-dev'

/**
 * Batch write items to DynamoDB with error handling
 */
async function batchWriteItems (tableName, items) {
  const BATCH_SIZE = 25 // DynamoDB limit

  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = items.slice(i, i + BATCH_SIZE)
    const params = {
      RequestItems: {
        [tableName]: batch.map(item => ({
          PutRequest: {
            Item: item
          }
        }))
      }
    }

    try {
      const result = await dynamodb.batchWrite(params).promise()
      
      // Handle unprocessed items
      if (result.UnprocessedItems && Object.keys(result.UnprocessedItems).length > 0) {
        console.warn(`⚠️  Warning: ${Object.keys(result.UnprocessedItems).length} unprocessed items for ${tableName}`)
      }
      
      console.log(`✅ Batch ${Math.floor(i / BATCH_SIZE) + 1}: Wrote ${batch.length} items to ${tableName}`)
    } catch (error) {
      console.error(`❌ Error writing batch to ${tableName}:`, error.message)
      throw error
    }
  }
}

/**
 * Migrate Users data
 */
async function migrateUsers () {
  console.log('\n📦 Migrating Users...')
  
  const usersFile = path.join(__dirname, '..', 'users', 'db.json')
  if (!fs.existsSync(usersFile)) {
    console.log('⚠️  Users db.json not found, skipping...')
    return
  }

  const data = JSON.parse(fs.readFileSync(usersFile, 'utf8'))
  
  const items = data.users.map(user => ({
    userId: user.id.toString(),
    email: user.email,
    name: user.name,
    createdAt: new Date().toISOString()
  }))

  await batchWriteItems(USERS_TABLE, items)
  console.log(`✅ Migrated ${items.length} users`)
}

/**
 * Migrate Threads data
 */
async function migrateThreads () {
  console.log('\n📦 Migrating Threads...')
  
  const threadsFile = path.join(__dirname, '..', 'threads', 'db.json')
  if (!fs.existsSync(threadsFile)) {
    console.log('⚠️  Threads db.json not found, skipping...')
    return
  }

  const data = JSON.parse(fs.readFileSync(threadsFile, 'utf8'))
  
  const items = data.threads.map(thread => ({
    threadId: thread.id.toString(),
    title: thread.title,
    description: thread.description || '',
    createdAt: thread.createdAt || new Date().toISOString()
  }))

  await batchWriteItems(THREADS_TABLE, items)
  console.log(`✅ Migrated ${items.length} threads`)
}

/**
 * Migrate Posts data
 */
async function migratePosts () {
  console.log('\n📦 Migrating Posts...')
  
  const postsFile = path.join(__dirname, '..', 'posts', 'db.json')
  if (!fs.existsSync(postsFile)) {
    console.log('⚠️  Posts db.json not found, skipping...')
    return
  }

  const data = JSON.parse(fs.readFileSync(postsFile, 'utf8'))
  
  const items = data.posts.map(post => ({
    postId: post.id.toString(),
    threadId: post.threadId ? post.threadId.toString() : '1',
    userId: post.userId ? post.userId.toString() : '1',
    content: post.content || post.body || '',
    title: post.title || '',
    createdAt: post.createdAt || new Date().toISOString()
  }))

  await batchWriteItems(POSTS_TABLE, items)
  console.log(`✅ Migrated ${items.length} posts`)
}

/**
 * Verify migration by counting items
 */
async function verifyMigration () {
  console.log('\n🔍 Verifying Migration...')
  
  const tables = [
    { name: USERS_TABLE, label: 'Users' },
    { name: THREADS_TABLE, label: 'Threads' },
    { name: POSTS_TABLE, label: 'Posts' }
  ]

  for (const table of tables) {
    try {
      const result = await dynamodb.scan({
        TableName: table.name,
        Select: 'COUNT'
      }).promise()
      
      console.log(`✅ ${table.label}: ${result.Count} items`)
    } catch (error) {
      console.error(`❌ Error verifying ${table.label}:`, error.message)
    }
  }
}

/**
 * Main migration function
 */
async function main () {
  console.log('🚀 Starting DynamoDB Migration...')
  console.log(`📍 Region: ${AWS.config.region}`)
  console.log(`📊 Tables: ${USERS_TABLE}, ${THREADS_TABLE}, ${POSTS_TABLE}`)

  try {
    await migrateUsers()
    await migrateThreads()
    await migratePosts()
    await verifyMigration()
    
    console.log('\n✅ Migration completed successfully!')
  } catch (error) {
    console.error('\n❌ Migration failed:', error)
    process.exit(1)
  }
}

// Run migration if called directly
if (require.main === module) {
  main()
}

module.exports = { migrateUsers, migrateThreads, migratePosts, verifyMigration }
