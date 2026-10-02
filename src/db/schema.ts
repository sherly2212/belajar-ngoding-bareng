import {
  mysqlTable,
  int,
  varchar,
  timestamp,
  datetime,
} from "drizzle-orm/mysql-core";

export const users = mysqlTable("users", {
  id: int().primaryKey().autoincrement(),
  name: varchar({ length: 255 }).notNull(),
  email: varchar({ length: 255 }).notNull().unique(),
  password: varchar({ length: 255 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const sessions = mysqlTable("sessions", {
  id: int().primaryKey().autoincrement(),
  token: varchar({ length: 255 }).notNull(),
  userId: int("user_id")
    .notNull()
    .references(() => users.id),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const passwordResets = mysqlTable("password_resets", {
  id: int().primaryKey().autoincrement(),
  userId: int("user_id")
    .notNull()
    .references(() => users.id),
  codeHash: varchar("code_hash", { length: 255 }).notNull(),
  expiresAt: datetime("expires_at").notNull(),
  attempts: int().notNull().default(0),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ---------- Rekap BPS (BARU) ----------

// Daftar satker (kab/kota). Kode 4 digit jadi kunci penghubung semua sumber data.
export const satker = mysqlTable("satker", {
  kode: varchar({ length: 4 }).primaryKey(),
  nama: varchar({ length: 255 }).notNull(),
});

// Data mentah kegiatan hasil impor dari sumber (sementara: mock DNA).
// id diambil dari sumber, jadi tidak autoincrement.
export const kegiatan = mysqlTable("kegiatan", {
  id: int().primaryKey(),
  idIndah: int("id_indah"),
  title: varchar({ length: 500 }).notNull(),
  year: int().notNull(),
  satkerKode: varchar("satker_kode", { length: 4 })
    .notNull()
    .references(() => satker.kode),
  statisticsType: varchar("statistics_type", { length: 50 }),
  collectionType: varchar("collection_type", { length: 50 }),
  status: varchar({ length: 50 }).notNull(),
  importedAt: timestamp("imported_at").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Session = typeof sessions.$inferSelect;
export type NewSession = typeof sessions.$inferInsert;
export type PasswordReset = typeof passwordResets.$inferSelect;
export type NewPasswordReset = typeof passwordResets.$inferInsert;
export type Satker = typeof satker.$inferSelect;
export type Kegiatan = typeof kegiatan.$inferSelect;
export type NewKegiatan = typeof kegiatan.$inferInsert;