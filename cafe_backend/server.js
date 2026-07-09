const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Sequelize, DataTypes } = require('sequelize');

const app = express();
const SECRET_KEY = process.env.JWT_SECRET || "cafe_secret_key";

app.use(cors());
app.use(express.json());

// 1. Database Setup (SQLite otomatis membuat file database baru)
const sequelize = new Sequelize({ dialect: 'sqlite', storage: './cafe.sqlite', logging: false });

// 2. Model & Relasi (Tabel Menu & Tabel Pesanan)
const User = sequelize.define('User', {
    username: { type: DataTypes.STRING, unique: true, allowNull: false },
    password: { type: DataTypes.STRING, allowNull: false },
    role: { type: DataTypes.STRING, allowNull: false, defaultValue: 'user' }
});


const Menu = sequelize.define('Menu', {
    name: { type: DataTypes.STRING, allowNull: false },
    price: { type: DataTypes.INTEGER, allowNull: false },
    category: { type: DataTypes.STRING, allowNull: false, defaultValue: 'Uncategorized' }
});

const Order = sequelize.define('Order', {
    quantity: { type: DataTypes.INTEGER, allowNull: false },
    totalPrice: { type: DataTypes.INTEGER, allowNull: false },
    status: { type: DataTypes.STRING, allowNull: false, defaultValue: 'Menunggu' }
});

// Relasi Dua Tabel (Syarat Tugas Akhir PMLP)
User.hasMany(Order, { foreignKey: 'userId' });
Order.belongsTo(User, { foreignKey: 'userId' });

Menu.hasMany(Order, { foreignKey: 'menuId' });
Order.belongsTo(Menu, { foreignKey: 'menuId' });

// Middleware JWT Auth
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Token diperlukan' });

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.status(403).json({ message: 'Token tidak valid' });
        req.user = user;
        next();
    });
};

// 3. Routing API
app.post('/api/register', async (req, res) => {
    try {
        const { username, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        await User.create({ username, password: hashedPassword });
        res.status(201).json({ message: "Registrasi Berhasil" });
    } catch (e) { res.status(400).json({ message: "Username sudah ada" }); }
});

app.post('/api/login', async (req, res) => {
    try {
        const { username, password = "" } = req.body;
        const user = await User.findOne({ where: { username } });
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(400).json({ message: "Akun tidak ditemukan" });
        }
        const token = jwt.sign({ id: user.id, role: user.role }, SECRET_KEY, { expiresIn: '1h' });
        res.json({ token, userId: user.id, role: user.role });

    } catch (e) { res.status(500).json({ message: "Terjadi kesalahan server" }); }
});

app.get('/api/menus', async (req, res) => {
    try {
        const menus = await Menu.findAll();
        res.json(menus);
    } catch (e) { res.status(500).json({ message: "Gagal mengambil data menu" }); }
});

app.post('/api/orders', authenticateToken, async (req, res) => {
    try {
        const { menuId, quantity } = req.body;

        // Validasi quantity harus angka positif
        if (!Number.isInteger(quantity) || quantity <= 0) {
            return res.status(400).json({ message: "Jumlah pesanan harus berupa angka positif" });
        }

        const menu = await Menu.findByPk(menuId);
        if (!menu) return res.status(404).json({ message: "Menu tidak ditemukan" });

        const totalPrice = menu.price * quantity;
        const order = await Order.create({
            quantity,
            totalPrice,
            status: 'Menunggu',
            userId: req.user.id,
            menuId: menuId
        });

        res.status(201).json({ message: "Pesanan berhasil dibuat!", order });
    } catch (e) { res.status(500).json({ message: "Gagal membuat pesanan" }); }
});


app.get('/api/orders', authenticateToken, async (req, res) => {
    try {
        const orders = await Order.findAll({
            where: { userId: req.user.id },
            include: [
                { model: Menu }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(orders);
    } catch (e) { 
        res.status(500).json({ message: "Gagal mengambil riwayat pesanan" });
    }
});

// Update status order: Menunggu -> Selesai
app.post('/api/orders/:id/complete', authenticateToken, async (req, res) => {
    try {
        const orderId = req.params.id;

        const isAdmin = req.user.role === 'admin';

        // user biasa hanya boleh mengubah miliknya sendiri,
        // admin boleh mengubah semua order.
        const whereClause = isAdmin ? { id: orderId } : { id: orderId, userId: req.user.id };

        const order = await Order.findOne({
            where: whereClause,
        });


        if (!order) return res.status(404).json({ message: 'Pesanan tidak ditemukan' });

        if (order.status !== 'Menunggu') {
            return res.status(400).json({ message: `Pesanan tidak bisa diubah (status saat ini: ${order.status})` });
        }

        order.status = 'Selesai';
        await order.save();

        res.json({ message: 'Pesanan selesai ✅', order });
    } catch (e) {
        res.status(500).json({ message: 'Gagal mengubah status pesanan' });
    }
});

// Sinkronisasi DB & Jalankan Server

sequelize.sync().then(async () => {
    const count = await Menu.count();
    if (count === 0) {
        await Menu.bulkCreate([
            // Kopi (5)
            { name: "Kopi Susu Gula Aren", price: 18000, category: "Kopi" },
            { name: "Americano", price: 15000, category: "Kopi" },
            { name: "Cappuccino", price: 20000, category: "Kopi" },
            { name: "Cafe Latte", price: 20000, category: "Kopi" },
            { name: "Caramel Macchiato", price: 24000, category: "Kopi" },
            
            // Non-Kopi (5)
            { name: "Matcha Latte", price: 22000, category: "Non-Kopi" },
            { name: "Red Velvet", price: 22000, category: "Non-Kopi" },
            { name: "Taro Latte", price: 20000, category: "Non-Kopi" },
            { name: "Chocolate Ice", price: 18000, category: "Non-Kopi" },
            { name: "Lemon Tea", price: 12000, category: "Non-Kopi" },
            
            // Snack (5)
            { name: "Kentang Goreng", price: 15000, category: "Snack" },
            { name: "Pisang Goreng Keju", price: 18000, category: "Snack" },
            { name: "Roti Bakar Coklat", price: 16000, category: "Snack" },
            { name: "Singkong Goreng", price: 14000, category: "Snack" },
            { name: "Mix Platter", price: 25000, category: "Snack" }
        ]);
    }
    app.listen(3000, () => console.log('Server Cafe siap di http://localhost:3000'));
});