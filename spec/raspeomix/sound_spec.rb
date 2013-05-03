require "spec_helper"
require "raspeomix"

include Raspeomix

# Mocking class
# Tried with double but couldn't conserver @muted state
# between calls
class SoundHandlerMock
  def initialize(channel="Master")
    @channel = channel
    @muted = false
    @volume = 0
  end

  def mute!
    @muted = true
  end

  def unmute!
    @muted = false
  end

  def muted?
    @muted
  end

  def volume=(value)
    @volume = value
  end

  def volume
    @volume
  end
end

describe "Raspeomix::SoundHandler" do
  it "should raise 'not implemented' for all methods" do
    s = SoundHandler.new
    [ :mute!, :unmute!, :muted?, :volume ].each do |m|
      expect { s.send(m) }.to raise_error(RuntimeError)
    end
    expect { s.volume=42 }.to raise_error(RuntimeError)
  end
end

describe "Raspeomix::SoundHandlerAlsa" do
  s = SoundHandlerAlsa.new

  it "should mute Master sound" do
    s.mute!
    s.muted?.should be true
  end

  it "should unmute Master sound" do
    s.unmute!
    s.muted?.should be false
  end

  it "should remute Master sound" do
    s.mute!
    s.muted?.should be true
  end
end

describe "Raspeomix::Sound" do
  before(:each) do
    # We do not want to issue calls to Faye
    Sound.any_instance.stub(:register).and_return(true)
    Sound.any_instance.stub(:publish).and_return(true)
    Sound.any_instance.stub(:subscribe).and_return(true)
    Sound.any_instance.stub(:start_heartbeat).and_return(true)

    @snd = Sound.new(SoundHandlerAlsa.new)
  end

  it "accepts mute message" do
    @snd.mute!
    @snd.muted?.should be true
  end

  it "accepts unmute message" do
    @snd.unmute!
    @snd.muted?.should be false
  end

  it "allows volume adjustment" do
    3.times do
      vol = rand(100)
      @snd.volume=vol
      # Alsa is not very precise...
      expect(@snd.volume).to be_within(1).of vol
      @snd.volume.should be_a_kind_of(Fixnum)
    end
  end

  it "refuses volumes below 0" do
    expect { @snd.volume=-1 }.to raise_error(VolumeOutOfBoundsError)
  end

  it "refuses volumes over 100" do
    expect { @snd.volume=101 }.to raise_error(VolumeOutOfBoundsError)
  end
end

