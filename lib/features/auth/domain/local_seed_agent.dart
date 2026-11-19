/// The agent `supabase/seed.sql` creates in the local Supabase stack. It owns the seed data.
///
/// These are not secrets: the same values are in the seed file, and the account exists
/// only in a database built from that file.
abstract final class LocalSeedAgent {
  static const email = 'agent@postfolio.com';
  static const password = 'password123';
}
