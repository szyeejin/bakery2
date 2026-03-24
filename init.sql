-- sql/init.sql

CREATE DATABASE IF NOT EXISTS bakery
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE bakery;

-- ========== 用户基础表 ==========
DROP TABLE IF EXISTS sys_user;
CREATE TABLE sys_user (
                          id          BIGINT PRIMARY KEY AUTO_INCREMENT,
                          phone       VARCHAR(20)  NOT NULL UNIQUE COMMENT '手机号(登录账号)',
                          password    VARCHAR(255) NOT NULL,
                          nickname    VARCHAR(50)  DEFAULT '' COMMENT '昵称',
                          avatar      VARCHAR(500) DEFAULT '' COMMENT '头像URL',
                          gender      TINYINT      DEFAULT 0  COMMENT '0未知 1男 2女',
                          birthday    DATE         DEFAULT NULL,
                          email       VARCHAR(100) DEFAULT '',
                          role        TINYINT      DEFAULT 0  COMMENT '0顾客 1店员 2店长',
                          status      TINYINT      DEFAULT 1  COMMENT '0禁用 1正常',
                          openid      VARCHAR(100) DEFAULT '' COMMENT '微信openid',
                          create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
                          update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '用户表';

-- ========== 会员信息表 ==========
DROP TABLE IF EXISTS user_member;
CREATE TABLE user_member (
                             id              BIGINT PRIMARY KEY AUTO_INCREMENT,
                             user_id         BIGINT         NOT NULL UNIQUE,
                             member_level    TINYINT        DEFAULT 0       COMMENT '0普通 1会员',
                             points          INT            DEFAULT 0       COMMENT '当前积分',
                             total_points    INT            DEFAULT 0       COMMENT '累计获得积分',
                             balance         DECIMAL(10,2)  DEFAULT 0.00    COMMENT '储值余额',
                             total_spent     DECIMAL(10,2)  DEFAULT 0.00    COMMENT '累计消费金额',
                             member_card_no  VARCHAR(50)    DEFAULT NULL UNIQUE COMMENT '会员卡号',
                             create_time     DATETIME       DEFAULT CURRENT_TIMESTAMP,
                             update_time     DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                             INDEX idx_user_id (user_id)
) COMMENT '会员信息表';

-- ========== 积分变动记录 ==========
DROP TABLE IF EXISTS member_points_log;
CREATE TABLE member_points_log (
                                   id            BIGINT PRIMARY KEY AUTO_INCREMENT,
                                   user_id       BIGINT       NOT NULL,
                                   points_change INT          NOT NULL COMMENT '变动积分(正增负减)',
                                   type          TINYINT      NOT NULL COMMENT '1消费 2评价 3兑换 4充值赠送 5系统调整',
                                   description   VARCHAR(200) DEFAULT '',
                                   order_id      BIGINT       DEFAULT NULL,
                                   create_time   DATETIME     DEFAULT CURRENT_TIMESTAMP,
                                   INDEX idx_user_id (user_id)
) COMMENT '积分变动记录';

-- ========== 储值充值记录 ==========
DROP TABLE IF EXISTS member_recharge_log;
CREATE TABLE member_recharge_log (
                                     id               BIGINT PRIMARY KEY AUTO_INCREMENT,
                                     user_id          BIGINT        NOT NULL,
                                     recharge_amount  DECIMAL(10,2) NOT NULL COMMENT '充值金额',
                                     gift_amount      DECIMAL(10,2) DEFAULT 0.00 COMMENT '赠送金额',
                                     payment_method   TINYINT       DEFAULT 1 COMMENT '1微信 2支付宝',
                                     create_time      DATETIME      DEFAULT CURRENT_TIMESTAMP,
                                     INDEX idx_user_id (user_id)
) COMMENT '充值记录';

-- ========== 收货地址 ==========
DROP TABLE IF EXISTS user_address;
CREATE TABLE user_address (
                              id             BIGINT PRIMARY KEY AUTO_INCREMENT,
                              user_id        BIGINT       NOT NULL,
                              contact_name   VARCHAR(50)  NOT NULL,
                              contact_phone  VARCHAR(20)  NOT NULL,
                              province       VARCHAR(50)  DEFAULT '',
                              city           VARCHAR(50)  DEFAULT '',
                              district       VARCHAR(50)  DEFAULT '',
                              detail_address VARCHAR(200) NOT NULL,
                              is_default     TINYINT      DEFAULT 0 COMMENT '0否 1默认',
                              create_time    DATETIME     DEFAULT CURRENT_TIMESTAMP,
                              update_time    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                              INDEX idx_user_id (user_id)
) COMMENT '收货地址';

-- ========== 员工信息表 ==========
DROP TABLE IF EXISTS staff_info;
CREATE TABLE staff_info (
                            id           BIGINT PRIMARY KEY AUTO_INCREMENT,
                            user_id      BIGINT       NOT NULL UNIQUE,
                            employee_no  VARCHAR(50)  UNIQUE COMMENT '工号',
                            position     VARCHAR(50)  DEFAULT '' COMMENT '职位:收银员/烘焙师/配送员',
                            hire_date    DATE         DEFAULT NULL,
                            salary       DECIMAL(10,2) DEFAULT 0.00,
                            status       TINYINT      DEFAULT 1 COMMENT '0离职 1在职',
                            create_time  DATETIME     DEFAULT CURRENT_TIMESTAMP,
                            update_time  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '员工信息';

-- ========== 初始管理员 (密码: admin123, BCrypt加密) ==========
INSERT INTO sys_user (phone, password, nickname, role, status) VALUES
    ('13800000000', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '超级管理员', 2, 1);

INSERT INTO user_member (user_id, member_level, member_card_no) VALUES
    (1, 1, 'MB0000000001');


USE bakery;

-- ========== 1. 商品分类表 ==========
DROP TABLE IF EXISTS product_category;
CREATE TABLE product_category (
                                  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
                                  name        VARCHAR(50) NOT NULL COMMENT '分类名称(如: 蛋糕, 甜品, 饮品)',
                                  sort        INT         DEFAULT 0 COMMENT '排序(越小越靠前)',
                                  status      TINYINT     DEFAULT 1 COMMENT '0禁用 1启用',
                                  create_time DATETIME    DEFAULT CURRENT_TIMESTAMP,
                                  update_time DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT '商品分类表';

-- ========== 2. 商品基础信息表 (SPU) ==========
DROP TABLE IF EXISTS product_spu;
CREATE TABLE product_spu (
                             id            BIGINT PRIMARY KEY AUTO_INCREMENT,
                             category_id   BIGINT        NOT NULL COMMENT '分类ID',
                             name          VARCHAR(100)  NOT NULL COMMENT '商品名称(如: 草莓奶油蛋糕)',
                             description   VARCHAR(500)  DEFAULT '' COMMENT '商品描述/成分',
                             cover_image   VARCHAR(500)  DEFAULT '' COMMENT '封面图URL',
                             base_price    DECIMAL(10,2) NOT NULL COMMENT '起步价',
                             status        TINYINT       DEFAULT 1 COMMENT '0下架 1上架',
                             sales_volume  INT           DEFAULT 0 COMMENT '基础销量',
                             create_time   DATETIME      DEFAULT CURRENT_TIMESTAMP,
                             update_time   DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                             INDEX idx_category (category_id)
) COMMENT '商品SPU表';

-- ========== 3. 商品规格表 (SKU) ==========
-- 蛋糕需要不同尺寸，比如 6寸、8寸，价格不同
DROP TABLE IF EXISTS product_sku;
CREATE TABLE product_sku (
                             id          BIGINT PRIMARY KEY AUTO_INCREMENT,
                             spu_id      BIGINT        NOT NULL COMMENT '关联的商品ID',
                             spec_name   VARCHAR(50)   NOT NULL COMMENT '规格名称(如: 6寸, 8寸, 标准杯)',
                             price       DECIMAL(10,2) NOT NULL COMMENT '当前规格实际价格',
                             stock       INT           DEFAULT 999 COMMENT '当前规格库存',
                             create_time DATETIME      DEFAULT CURRENT_TIMESTAMP,
                             INDEX idx_spu (spu_id)
) COMMENT '商品SKU规格表';

-- 插入一些测试数据
INSERT INTO product_category (name, sort) VALUES ('生日蛋糕', 1), ('下午茶甜品', 2), ('特调饮品', 3);

INSERT INTO product_spu (category_id, name, description, base_price) VALUES
                                                                         (1, '草莓魔法蛋糕', '新鲜草莓+动物奶油', 168.00),
                                                                         (2, '抹茶千层', '宇治抹茶，入口即化', 38.00);

INSERT INTO product_sku (spu_id, spec_name, price) VALUES
                                                       (1, '6寸 (适合2-3人)', 168.00),
                                                       (1, '8寸 (适合4-6人)', 228.00),
                                                       (2, '切件', 38.00);
