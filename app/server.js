const express = require("express");
const path = require("path");
const { Pool } = require("pg");

const app = express();
const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || "v1.0";
const HOSTNAME = process.env.HOSTNAME || "unknown";

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || "5432", 10),
  database: process.env.DB_NAME || "devops_demo",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD,
  max: 5,
  connectionTimeoutMillis: 5000,
  ssl: process.env.DB_HOST ? { rejectUnauthorized: false } : false,
});

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

let nodeId = null;
let nodeLabel = "Node-??";

// Initialize: register this instance in the DB and get a node ID
async function registerNode() {
  try {
    // Create table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS nodes (
        id SERIAL PRIMARY KEY,
        container_id VARCHAR(255) UNIQUE NOT NULL,
        registered_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Register this container and get the assigned ID
    const result = await pool.query(
      `INSERT INTO nodes (container_id)
       VALUES ($1)
       ON CONFLICT (container_id) DO UPDATE SET registered_at = NOW()
       RETURNING id`,
      [HOSTNAME]
    );

    nodeId = result.rows[0].id;
    nodeLabel = `Node-${String(nodeId).padStart(2, "0")}`;
    console.log(`Registered as ${nodeLabel} (container: ${HOSTNAME})`);
  } catch (err) {
    console.error("Failed to register node in DB:", err.message);
    // Fallback: use last 2 digits of hostname hash
    const hash = HOSTNAME.split("").reduce(
      (acc, c) => ((acc << 5) - acc + c.charCodeAt(0)) | 0,
      0
    );
    nodeId = Math.abs(hash) % 100;
    nodeLabel = `Node-${String(nodeId).padStart(2, "0")}`;
    console.log(`Using fallback ID: ${nodeLabel}`);
  }
}

// Routes
app.get("/", (req, res) => {
  res.render("index", {
    nodeLabel,
    version: APP_VERSION,
    hostname: HOSTNAME,
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy", node: nodeLabel, version: APP_VERSION });
});

app.get("/api/info", (req, res) => {
  res.json({
    node: nodeLabel,
    version: APP_VERSION,
    hostname: HOSTNAME,
    uptime: process.uptime(),
  });
});

// Graceful shutdown: deregister node
async function shutdown(signal) {
  console.log(`${signal} received. Deregistering ${nodeLabel}...`);
  try {
    await pool.query("DELETE FROM nodes WHERE container_id = $1", [HOSTNAME]);
    console.log(`Deregistered ${nodeLabel}`);
  } catch (err) {
    console.error("Error deregistering node:", err.message);
  }
  await pool.end();
  process.exit(0);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

// Start server
registerNode().then(() => {
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`${nodeLabel} running on port ${PORT} | Version: ${APP_VERSION}`);
  });
});
