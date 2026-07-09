require("dotenv").config();
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const { createClient } = require("@supabase/supabase-js");

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Setup Multer for memory storage
const upload = multer({ storage: multer.memoryStorage() });

// Initialize general Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error(
    "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env",
  );
  process.exit(1);
}

const mainSupabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: { persistSession: false },
});

// Helper function to get request-specific Supabase client (with user token for RLS)
const getSupabaseClient = (req) => {
  const authHeader = req.headers.authorization;
  const token =
    authHeader && authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

  const options = {
    auth: { persistSession: false },
  };

  if (token) {
    options.global = {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    };
  }

  return createClient(supabaseUrl, supabaseAnonKey, options);
};

// Middleware: Authenticate Request via Supabase JWT
const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token =
    authHeader && authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

  if (!token) {
    return res
      .status(401)
      .json({
        error: "Token otentikasi tidak ditemukan (Authorization header).",
      });
  }

  try {
    const {
      data: { user },
      error,
    } = await mainSupabase.auth.getUser(token);

    if (error || !user) {
      return res
        .status(401)
        .json({ error: "Sesi otentikasi tidak valid atau telah kedaluwarsa." });
    }

    req.user = user;
    req.token = token;
    next();
  } catch (err) {
    return res
      .status(500)
      .json({ error: `Gagal memverifikasi token: ${err.message}` });
  }
};

// =========================================================================
// API ENDPOINTS
// =========================================================================

// 1. Register User
app.post("/api/auth/register", async (req, res) => {
  const { email, password, full_name } = req.body;

  if (!email || !password || !full_name) {
    return res
      .status(400)
      .json({ error: "Email, password, dan nama lengkap wajib diisi." });
  }

  try {
    const { data, error } = await mainSupabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: full_name,
        },
      },
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json({
      message: "Registrasi sukses!",
      session: data.session,
      user: data.user,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 2. Login User
app.post("/api/auth/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email dan password wajib diisi." });
  }

  try {
    const { data, error } = await mainSupabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json({
      message: "Login sukses!",
      session: data.session,
      user: data.user,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 3. Get Authenticated User Profile
app.get("/api/profile", authMiddleware, async (req, res) => {
  try {
    const client = getSupabaseClient(req);
    const { data, error } = await client
      .from("profiles")
      .select("*")
      .eq("id", req.user.id)
      .maybeSingle();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (!data) {
      // Fallback if profiles trigger hasn't finished, return user metadata
      return res.status(200).json({
        id: req.user.id,
        full_name: req.user.user_metadata?.full_name || "Pengguna KapanBasi",
        email: req.user.email,
        avatar_url: req.user.user_metadata?.avatar_url || null,
        created_at: req.user.created_at,
      });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 3b. Update Profile (full_name & avatar_url)
app.put("/api/profile", authMiddleware, async (req, res) => {
  const { full_name, avatar_url } = req.body;
  if (!full_name) {
    return res.status(400).json({ error: "full_name wajib diisi." });
  }
  try {
    const client = getSupabaseClient(req);
    const updatePayload = { full_name };
    if (avatar_url !== undefined) updatePayload.avatar_url = avatar_url;

    const { data, error } = await client
      .from("profiles")
      .update(updatePayload)
      .eq("id", req.user.id)
      .select()
      .single();

    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 3c. Change Password
app.put("/api/profile/password", authMiddleware, async (req, res) => {
  const { new_password } = req.body;
  if (!new_password || new_password.length < 6) {
    return res.status(400).json({ error: "Password baru minimal 6 karakter." });
  }
  try {
    const client = getSupabaseClient(req);
    const { error } = await client.auth.updateUser({ password: new_password });
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ message: "Password berhasil diperbarui." });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 4. Get Foods (Owned by user, RLS enforced)
app.get("/api/foods", authMiddleware, async (req, res) => {
  try {
    const client = getSupabaseClient(req);
    const { data, error } = await client
      .from("foods")
      .select("*")
      .order("expiry_date", { ascending: true });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 5. Insert Food
app.post("/api/foods", authMiddleware, async (req, res) => {
  try {
    const client = getSupabaseClient(req);
    // Inject current user ID to follow schema constraint
    const foodPayload = {
      ...req.body,
      user_id: req.user.id,
    };

    const { data, error } = await client
      .from("foods")
      .insert(foodPayload)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(201).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 6. Update Food
app.put("/api/foods/:id", authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const client = getSupabaseClient(req);
    const foodPayload = {
      ...req.body,
      user_id: req.user.id,
    };

    const { data, error } = await client
      .from("foods")
      .update(foodPayload)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 7. Delete Food
app.delete("/api/foods/:id", authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const client = getSupabaseClient(req);
    const { error } = await client.from("foods").delete().eq("id", id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json({ message: "Item berhasil dihapus" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 8. Get Storage Locations
app.get("/api/storage-locations", async (req, res) => {
  try {
    const { data, error } = await mainSupabase
      .from("storage_locations")
      .select("*");

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    return res.status(200).json(data);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 9. Upload Image
app.post(
  "/api/upload",
  authMiddleware,
  upload.single("image"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res
          .status(400)
          .json({ error: "Tidak ada berkas gambar yang dikirim." });
      }

      const client = getSupabaseClient(req);
      const fileExtension = req.file.originalname.split(".").pop() || "jpg";
      const uniqueFileName = `${Date.now()}_${Math.random().toString(36).substring(2, 11)}.${fileExtension}`;

      const { data, error } = await client.storage
        .from("food-images")
        .upload(uniqueFileName, req.file.buffer, {
          contentType: req.file.mimetype,
          upsert: true,
        });

      if (error) {
        return res
          .status(400)
          .json({ error: `Gagal upload ke storage: ${error.message}` });
      }

      const {
        data: { publicUrl },
      } = client.storage.from("food-images").getPublicUrl(uniqueFileName);

      return res.status(200).json({ imageUrl: publicUrl });
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  },
);

// Start Express Server
app.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`🚀 KapanBasi Custom Backend running on port ${PORT}`);
  console.log(`===================================================`);
});
