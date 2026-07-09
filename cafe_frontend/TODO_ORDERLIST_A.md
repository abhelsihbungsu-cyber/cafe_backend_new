# TODO - Fokus A (UX loading saat klik “selesai”)

## Step 1 — Review state/event yang diperlukan
- Tambahkan state baru untuk action: `OrderActionLoading(orderId: ...)`.

## Step 2 — Update OrderBloc
- `MarkOrderDone` sekarang meng-emit `OrderActionLoading(orderId: event.orderId)` sebelum request POST.
- Setelah request selesai: tetap `add(FetchOrders())` untuk refresh list.

## Step 3 — Update UI OrderListScreen
- Tambahkan `BlocBuilder<OrderBloc, OrderState>` di tombol “selesai” per-item.
- Saat `OrderActionLoading.orderId == order.id`:
  - tombol diganti dengan `CircularProgressIndicator` kecil
  - tombol tidak bisa ditekan (karena diganti widget loading)

## Step 4 — Validasi cepat
- `flutter analyze` berhasil (tidak fatal) dan hanya issue non-tugas.

