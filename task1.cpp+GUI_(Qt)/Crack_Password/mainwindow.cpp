#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QFile>
#include <QTextStream>
#include <QMessageBox>

const QString CORRECT_PASSWORD = "aabbO";

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_pushButton_clicked()
{
    if (dictionaryAttack()) {
        ui->lineEdit->setText("aabbO");
        ui->label->setText("Password found via Dictionary Attack!");
    } else if (bruteForceAttack()) {
        ui->lineEdit->setText("aabbO");
        ui->label->setText("Password found via Brute Force Attack!");
    } else {
        ui->lineEdit->setText("Not Found");
        ui->label->setText("Password NOT found!");
    }
}

//1. Dictionary_Based function:
bool MainWindow::dictionaryAttack() {
    QFile file("./words_alpha.txt");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QMessageBox::warning(this, "Error", "Could not open dictionary file!");
        return false;
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        ui->lineEdit->setText(line);
        QCoreApplication::processEvents();

        if (line == CORRECT_PASSWORD) {
            return true;
        }
    }
    return false;
}

//2. Brute_Force function:
bool MainWindow::bruteForceAttack() {
    QString charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int len = charset.size();

    for (int i = 0; i < len; ++i)
        for (int j = 0; j < len; ++j)
            for (int k = 0; k < len; ++k)
                for (int l = 0; l < len; ++l)
                    for (int m = 0; m < len; ++m) {
                        QString attempt = QString("%1%2%3%4%5")
                        .arg(charset[i])
                            .arg(charset[j])
                            .arg(charset[k])
                            .arg(charset[l])
                            .arg(charset[m]);

                        ui->lineEdit->setText(attempt);
                        QCoreApplication::processEvents();

                        if (attempt == CORRECT_PASSWORD) {
                            return true;
                        }
                    }
    return false;
}
