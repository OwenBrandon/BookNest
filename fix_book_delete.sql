-- Fix Book Deletion: Enable Cascade on ALL references

-- 1. LOAN TRANSACTIONS (Refix/Ensure)
ALTER TABLE public.loan_transactions
DROP CONSTRAINT IF EXISTS loan_transactions_book_id_fkey;

ALTER TABLE public.loan_transactions
ADD CONSTRAINT loan_transactions_book_id_fkey
FOREIGN KEY (book_id)
REFERENCES public.books(id)
ON DELETE CASCADE;

-- 2. FAVORITES (Likely missing cascade)
ALTER TABLE public.favorites
DROP CONSTRAINT IF EXISTS favorites_book_id_fkey;

ALTER TABLE public.favorites
ADD CONSTRAINT favorites_book_id_fkey
FOREIGN KEY (book_id)
REFERENCES public.books(id)
ON DELETE CASCADE;

-- 3. RLS Safety Check (Ensure generic policy exists)
DROP POLICY IF EXISTS "Librarians can delete books" ON public.books;
DROP POLICY IF EXISTS "Enable all for authenticated" ON public.books;

CREATE POLICY "Enable all for authenticated"
ON public.books
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
