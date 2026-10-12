import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !anonKey || !serviceKey) console.warn('Supabase configuration is incomplete. Set SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY.');
export const supabase = createClient(url || 'https://placeholder.supabase.co', anonKey || 'placeholder-anon-key', { auth: { persistSession: false } });
export const adminSupabase = createClient(url || 'https://placeholder.supabase.co', serviceKey || 'placeholder-service-key', { auth: { persistSession: false, autoRefreshToken: false } });
