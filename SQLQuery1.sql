--1) Hãy dùng câu lệnh, tạo cơ sở dữ liệu với tên QuanLyNhanSu

USE master
GO

DROP DATABASE IF EXISTS QUANLYNHANSU
CREATE DATABASE QUANLYNHANSU
GO

--focus database mới tạo
USE QUANLYNHANSU
GO

--2)Hãy dùng câu lệnh tạo các bảng (bao gồm khóa chính, khóa ngoại, kiểu dữ liệu) và tự liên kết giữa các bảng: 

--tạo bảng nhân viên

DROP TABLE IF EXISTS NhanVien
CREATE TABLE NhanVien
(
 MaNV	    INT          PRIMARY KEY,
 TenNV	    NVARCHAR(70) NOT NULL, 
 Tuoi       INT          NOT NULL, 
 GioiTinh   INT                 ,	 
)
GO

--tạo bảng dự án

DROP TABLE IF EXISTS DuAn
CREATE TABLE DuAn
(
 MaDA	  INT           PRIMARY KEY,
 TenDA	  NVARCHAR(50)  NOT NULL, 
 NgayBD   DATETIME      NOT NULL, 
 NgayKT   DATETIME      NOT NULL,	 
)
GO

--tạo bảng tham gia
DROP TABLE IF EXISTS ThamGia
CREATE TABLE ThamGia
(
 MaNV	     INT ,
 MaDA	     INT ,
 NgayVaoDA   DATETIME ,
 NgayRaDA    DATETIME  NOT NULL,
 PRIMARY KEY(MaNV,MaDA,NgayVaoDA)	 
)
GO

--tạo liên kết (đi từ nhiều sang 1)

ALTER TABLE ThamGia
ADD CONSTRAINT FK_ThamGia_NhanVien
FOREIGN KEY(MaNV)
REFERENCES NhanVien(MaNV)
GO

ALTER TABLE ThamGia
ADD CONSTRAINT FK_ThamGia_DuAn
FOREIGN KEY(MaDA)
REFERENCES DuAn(MaDA)
GO

--câu 3:Tạo trigger để kiểm tra mỗi khi thêm vào bảng NhanVien. 
--Nếu tuổi quá 45 và giới tính là 0 hoặc tuổi quá 50 giới tính là 1 thì 
--không cho phép thêm vào bảng và báo lỗi 'Tuoi khong hop le' ra màn hình.

CREATE TRIGGER Them_NhanVien
ON dbo.NhanVien
AFTER INSERT
AS 
BEGIN
   DECLARE @tuoi INT, @gioitinh INT
	SELECT @tuoi = Tuoi FROM inserted
	SELECT @gioitinh = GioiTinh FROM inserted

	IF (@tuoi >= 45 AND @gioitinh = 0) OR( @tuoi >= 50 AND @gioitinh = 1)
	BEGIN
			SELECT N'Tuổi không hợp lệ' Error
			ROLLBACK TRANSACTION
	END
END
GO

-------nhập bảng NhanVien---------------
INSERT INTO NhanVien(MaNV,TenNV,Tuoi,GioiTinh)
VALUES(1, N'Nguyễn Hoàng Anh', 19, 0)
INSERT INTO NhanVien(MaNV,TenNV,Tuoi,GioiTinh)
VALUES(2, N'Trần Hạo Bình', 33, 1)
INSERT INTO NhanVien(MaNV,TenNV,Tuoi,GioiTinh)
VALUES(3, N'Bành Đại Kiện', 30, Null)
INSERT INTO NhanVien(MaNV,TenNV,Tuoi,GioiTinh)
VALUES(6, N'Quách Đại Lộ', 32, Null)
INSERT INTO NhanVien(MaNV,TenNV,Tuoi,GioiTinh)
VALUES(4, N'Hứa Quảng Hà', 24, 0)
GO

-------nhập bảng DuAn ---------------
INSERT INTO DuAn (MaDA,TenDA,NgayBD,NgayKT)
VALUES(1, N'Phần mềm quản lý trường học', '2005/2/2', '2007/5/5')
INSERT INTO DuAn (MaDA,TenDA, NgayBD, NgayKT)
VALUES(2, N'Hệ thống dự báo thời tiết', '2005/3/3', '2009/3/8')
INSERT INTO DuAn (MaDA,TenDA, NgayBD, NgayKT)
VALUES(3, N'Hệ thống xác thực vân tay', '2005/7/3', '2009/5/8')
GO

-------nhập bảng ThamGia---------------

INSERT INTO ThamGia (MaNV,MaDA,NgayVaoDA,NgayRaDA)
VALUES (1, 1, '2006/3/3', '2007/5/4')
INSERT INTO ThamGia (MaNV,MaDA,NgayVaoDA,NgayRaDA)
VALUES (2, 1, '2006/2/2', '2007/5/5')
INSERT INTO ThamGia (MaNV,MaDA,NgayVaoDA,NgayRaDA)
VALUES (1, 2, '2006/3/3', '2007/5/5')
INSERT INTO ThamGia (MaNV,MaDA,NgayVaoDA,NgayRaDA)
VALUES (3, 2, '2006/3/3', '2007/4/4')
GO

--câu 4: Tạo trigger để kiểm tra mỗi khi có sự thay đổi dữ liệu bảng ThamGia.
--Thì 1 nhân viên không được phép tham gia quá ba dự án và báo lỗi ‘nhân viên không được tham gia quá ba dự án’.

CREATE TRIGGER SoLan_ThamGia
ON dbo.ThamGia
AFTER INSERT
AS 
BEGIN
    DECLARE @SoLan INT
	SELECT @SoLan  = COUNT(MaDA) FROM inserted
	IF @SoLan > 3 
	BEGIN
			SELECT N'Nhân viên không được tham gia quá ba dự án' Error
			ROLLBACK TRANSACTION
	END
END
GO

--5)Viết stored procedure, hiện ra tên dự án, ứng với mỗi dự án có số lượng người tham gia. 
--Nếu dự án không có người tham gia thì số lượng là 0.

DROP PROCEDURE IF EXISTS sp_Da
GO
CREATE PROCEDURE sp_Da
AS
BEGIN
	SELECT TenDA, COUNT(MaNV) AS SoLuong
	FROM   DuAn  
			   LEFT JOIN ThamGia ON DuAn.MaDA = ThamGia.MaDA
	GROUP BY TenDA
	ORDER BY SoLuong DESC
END
GO

--6)	Viết stored procedure, hiện ra bảng như sau. 
--Trong đó giới tính là 0 hiện ra "Nam", là 1 hiện ra "Nữ", trường hợp khác hiện ra "Không rõ". 

DROP PROCEDURE IF EXISTS bang_gioi_tinh_nhan_vien
GO
CREATE PROCEDURE bang_gioi_tinh_nhan_vien
AS
BEGIN
	SELECT TenNV, Tuoi,
		CASE WHEN GioiTinh = 0 THEN N'Nam'
		     WHEN GioiTinh = 1 THEN  N'Nữ'
		     WHEN GioiTinh IS NULL THEN  N'Không rõ'
	   END GT
     FROM dbo.NhanVien
END
GO

--7)Viết stored procedure, để xem được tên dự án và tên nhân viên tham gia dự án đồng thời với ngày vào và ngày ra khỏi dự án. 

DROP PROCEDURE IF EXISTS cau_7
GO
CREATE PROCEDURE cau_7
AS
BEGIN
		SELECT NhanVien.TenNV, DuAn.TenDA, ThamGia.NgayRaDA, ThamGia.NgayVaoDA
		FROM   ThamGia 
			JOIN NhanVien ON ThamGia.MaNV = NhanVien.MaNV 
			JOIN DuAn ON ThamGia.MaDA = DuAn.MaDA

END
GO

--8) Viết stored procedure, liệt kê tất cả nhân viên chưa tham gia vào đồ án nào.

DROP PROCEDURE IF EXISTS nhan_vien_chua_tham_gia_du_an
GO
CREATE PROCEDURE nhan_vien_chua_tham_gia_du_an
AS
BEGIN
	SELECT * FROM NhanVien
		WHERE NhanVien.MaNV NOT IN 
		(SELECT ThamGia.MaNV FROM ThamGia)
	END
GO

--9)Sử dụng trigger dạng instead of delete, hãy viết câu trigger để bắt sự kiện khi chạy câu 
--DELETE FROM NhanVien  WHERE MaNV=1 nó sẽ xóa nhân viên đó ra khỏi bảng NhanVien  

CREATE TRIGGER Delete_all
ON NhanVien
INSTEAD OF DELETE
AS 
BEGIN
		DECLARE @MaNV INT 
		SELECT @MaNV  = MaNV FROM Deleted
		DELETE FROM DuAn WHERE MaDA = (SELECT MaDA FROM ThamGia WHERE MaNV = @MaNV)
		DELETE FROM ThamGia WHERE MaNV = @MaNV
		DELETE FROM NhanVien WHERE MaNV = @MaNV
	
END
GO

--10)Hãy sử dụng nonclustered index lên cột TenDA trong bảng DuAn

CREATE NONCLUSTERED INDEX cau_10
ON dbo.DuAn(TenDA);