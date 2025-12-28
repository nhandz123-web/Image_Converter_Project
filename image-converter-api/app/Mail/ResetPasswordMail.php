<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ResetPasswordMail extends Mailable
{
    use Queueable, SerializesModels;

    public $otp;

public function __construct($otp) {
    $this->otp = $otp;
}

public function build() {
    return $this->subject('Mã xác nhận đổi mật khẩu')
                ->html("<h3>Mã OTP của bạn là: <b style='color:red;'>{$this->otp}</b></h3>
                        <p>Mã này dùng để khôi phục mật khẩu trên ứng dụng.</p>");
}
}