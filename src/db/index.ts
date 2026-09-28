import { drizzle } from "drizzle-orm/mysql2";
import mysql from "mysql2/promise";
import * as schema from "./schema";
import { config } from "../config";

export const poolConnection = mysql.createPool(config.databaseUrl);

export const db = drizzle(poolConnection, { schema, mode: "default" });